#!/bin/bash
# lib/config.sh — Parser simples de configuração YAML-like
# Não requer yq — parseia o subset necessário com bash puro.
# Formato suportado: listas simples sob chaves (sem nesting profundo).

# Lê uma lista de valores sob uma chave de um arquivo YAML simples
# Uso: config_get_list "packages.install" config/defaults.yml
config_get_list() {
    local key="$1"
    local file="$2"

    if [[ ! -f "$file" ]]; then
        log_error "Arquivo de configuração não encontrado: $file"
        return 1
    fi

    local in_section=false
    local depth=""

    # Converte "packages.install" → busca "packages:" depois "install:"
    local top_key="${key%%.*}"
    local sub_key="${key#*.}"

    if [[ "$top_key" == "$sub_key" ]]; then
        # Chave sem ponto — busca diretamente
        sub_key=""
    fi

    local found_top=false
    local found_sub=false

    while IFS= read -r line; do
        # Ignora comentários e linhas vazias
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        # Detecta chave top-level (sem indentação)
        if [[ "$line" =~ ^${top_key}: ]]; then
            found_top=true
            if [[ -z "$sub_key" ]]; then
                found_sub=true
            fi
            continue
        fi

        # Se não estamos na seção top, pula
        if [[ "$found_top" != "true" ]]; then
            continue
        fi

        # Se encontramos outra chave top-level, saímos
        if [[ "$line" =~ ^[a-zA-Z] ]]; then
            break
        fi

        # Busca sub-key
        if [[ -n "$sub_key" && "$found_sub" != "true" ]]; then
            if [[ "$line" =~ ^[[:space:]]+${sub_key}: ]]; then
                found_sub=true
            fi
            continue
        fi

        # Se estamos na seção certa, extrai itens de lista
        if [[ "$found_sub" == "true" ]]; then
            # Se encontra outra sub-key, para
            if [[ "$line" =~ ^[[:space:]]+[a-zA-Z_]+: ]]; then
                break
            fi
            # Extrai item de lista (- valor)
            if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.*) ]]; then
                echo "${BASH_REMATCH[1]}"
            fi
        fi
    done < "$file"
}

# Lê um valor escalar de uma chave
# Uso: config_get "desktop.theme" config/defaults.yml
config_get() {
    local key="$1"
    local file="$2"

    if [[ ! -f "$file" ]]; then
        log_error "Arquivo de configuração não encontrado: $file"
        return 1
    fi

    local top_key="${key%%.*}"
    local sub_key="${key#*.}"

    local found_top=false

    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        if [[ "$line" =~ ^${top_key}: ]]; then
            found_top=true
            if [[ "$top_key" == "$sub_key" ]]; then
                # Valor na mesma linha
                local val="${line#*: }"
                [[ "$val" != "${top_key}:" ]] && echo "$val"
                return
            fi
            continue
        fi

        if [[ "$found_top" != "true" ]]; then
            continue
        fi

        if [[ "$line" =~ ^[a-zA-Z] ]]; then
            break
        fi

        if [[ "$line" =~ ^[[:space:]]+${sub_key}:[[:space:]]+(.*) ]]; then
            echo "${BASH_REMATCH[1]}"
            return
        fi
    done < "$file"
}

# Carrega um perfil (merge defaults + profile)
# Uso: load_profile "minimal"
load_profile() {
    local profile="${1:-minimal}"
    local defaults="$QXDC_ROOT/config/defaults.yml"
    local profile_file="$QXDC_ROOT/config/profiles/${profile}.yml"

    if [[ ! -f "$defaults" ]]; then
        log_error "Arquivo de defaults não encontrado: $defaults"
        return 1
    fi

    # Profile file é opcional — se não existir, usa só defaults
    if [[ -n "$profile" && -f "$profile_file" ]]; then
        QXDC_CONFIG="$profile_file"
        log_info "Perfil carregado: $profile"
    else
        QXDC_CONFIG="$defaults"
        if [[ "$profile" != "defaults" ]]; then
            log_warn "Perfil '$profile' não encontrado, usando defaults."
        fi
    fi

    export QXDC_CONFIG
}
