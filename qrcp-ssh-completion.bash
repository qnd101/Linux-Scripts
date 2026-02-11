_qrcp-ssh_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}" # The current word being typed
    prev="${COMP_WORDS[COMP_CWORD-1]}" # The previous word
    opts="receive send" # Available options

    case "${prev}" in
        "send")
            # Suggest specific flags if the previous word was 'build'
            COMPREPLY=( $(compgen -f -- "${cur}") )
            return 0
            ;;
        *)
            ;;
    esac

    # Default: suggest the main options
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
}

complete -F _qrcp-ssh_completions -o filenames qrcp-ssh
