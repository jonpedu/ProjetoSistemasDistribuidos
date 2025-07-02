#!/bin/bash

echo "🔍 [MONITOR] Iniciando monitoramento de logs do InterSCity..."
echo "📋 [MONITOR] Este script irá mostrar logs relacionados ao InterSCity em tempo real"
echo "📋 [MONITOR] Pressione Ctrl+C para parar o monitoramento"
echo ""

# Função para mostrar logs do Middleware Service
show_middleware_logs() {
    echo "📊 [MONITOR] Logs do Middleware Service (InterSCity):"
    docker logs -f dtm-middleware 2>&1 | grep -E "\[INTERSCITY\]|\[MIDDLEWARE\]" --color=always
}

# Função para mostrar logs do InterSCity Adapter Service
show_interscity_logs() {
    echo "📊 [MONITOR] Logs do InterSCity Adapter Service:"
    docker logs -f dtm-interscity-adapter 2>&1 | grep -E "\[INTERSCITY|\[INTERSCITY ADAPTER\]|\[INTERSCITY SERVICE\]" --color=always
}

# Função para mostrar logs do RabbitMQ
show_rabbitmq_logs() {
    echo "📊 [MONITOR] Logs do RabbitMQ:"
    docker logs -f dtm-rabbitmq 2>&1 | grep -E "channel|queue|exchange|binding" --color=always
}

# Verificar se os containers estão rodando
check_containers() {
    echo "🔍 [MONITOR] Verificando status dos containers..."
    
    if ! docker ps | grep -q "dtm-middleware"; then
        echo "❌ [MONITOR] Container dtm-middleware não está rodando!"
        return 1
    fi
    
    if ! docker ps | grep -q "dtm-interscity-adapter"; then
        echo "❌ [MONITOR] Container dtm-interscity-adapter não está rodando!"
        return 1
    fi
    
    if ! docker ps | grep -q "dtm-rabbitmq"; then
        echo "❌ [MONITOR] Container dtm-rabbitmq não está rodando!"
        return 1
    fi
    
    echo "✅ [MONITOR] Todos os containers estão rodando!"
    return 0
}

# Menu principal
show_menu() {
    echo ""
    echo "🎯 [MONITOR] Escolha uma opção:"
    echo "1) Monitorar logs do Middleware Service (InterSCity)"
    echo "2) Monitorar logs do InterSCity Adapter Service"
    echo "3) Monitorar logs do RabbitMQ"
    echo "4) Monitorar todos os logs (recomendado)"
    echo "5) Verificar status dos containers"
    echo "6) Sair"
    echo ""
    read -p "Digite sua opção (1-6): " choice
}

# Executar opção selecionada
execute_choice() {
    case $choice in
        1)
            echo "📊 [MONITOR] Iniciando monitoramento do Middleware Service..."
            show_middleware_logs
            ;;
        2)
            echo "📊 [MONITOR] Iniciando monitoramento do InterSCity Adapter Service..."
            show_interscity_logs
            ;;
        3)
            echo "📊 [MONITOR] Iniciando monitoramento do RabbitMQ..."
            show_rabbitmq_logs
            ;;
        4)
            echo "📊 [MONITOR] Iniciando monitoramento completo..."
            echo "📋 [MONITOR] Use Ctrl+C para parar"
            echo ""
            # Usar tmux para mostrar múltiplos logs simultaneamente
            if command -v tmux &> /dev/null; then
                tmux new-session -d -s interscity-monitor
                tmux split-window -h -t interscity-monitor
                tmux split-window -v -t interscity-monitor
                
                tmux send-keys -t interscity-monitor:0.0 "docker logs -f dtm-middleware 2>&1 | grep -E '\[INTERSCITY\]|\[MIDDLEWARE\]' --color=always" Enter
                tmux send-keys -t interscity-monitor:0.1 "docker logs -f dtm-interscity-adapter 2>&1 | grep -E '\[INTERSCITY|\[INTERSCITY ADAPTER\]|\[INTERSCITY SERVICE\]' --color=always" Enter
                tmux send-keys -t interscity-monitor:0.2 "docker logs -f dtm-rabbitmq 2>&1 | grep -E 'channel|queue|exchange|binding' --color=always" Enter
                
                tmux attach-session -t interscity-monitor
            else
                echo "⚠️ [MONITOR] tmux não encontrado. Mostrando logs sequencialmente..."
                echo "📊 [MONITOR] Middleware Service:"
                show_middleware_logs &
                echo "📊 [MONITOR] InterSCity Adapter Service:"
                show_interscity_logs &
                echo "📊 [MONITOR] RabbitMQ:"
                show_rabbitmq_logs &
                wait
            fi
            ;;
        5)
            check_containers
            ;;
        6)
            echo "👋 [MONITOR] Saindo..."
            exit 0
            ;;
        *)
            echo "❌ [MONITOR] Opção inválida!"
            ;;
    esac
}

# Loop principal
while true; do
    show_menu
    execute_choice
    echo ""
    read -p "Pressione Enter para continuar..."
done 