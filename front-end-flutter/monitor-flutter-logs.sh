#!/bin/bash

# Script para monitorar logs HTTP do Flutter
# Uso: ./monitor-flutter-logs.sh

echo "🔍 Monitor de Logs HTTP - Flutter InterSCity"
echo "=============================================="
echo ""
echo "Este script irá executar o Flutter e filtrar apenas os logs HTTP"
echo "Pressione Ctrl+C para parar o monitoramento"
echo ""
echo "Iniciando monitoramento..."

# Executa o Flutter e filtra apenas os logs HTTP
flutter run --verbose 2>&1 | grep --line-buffered "FLUTTER HTTP"

echo ""
echo "✅ Monitoramento finalizado" 