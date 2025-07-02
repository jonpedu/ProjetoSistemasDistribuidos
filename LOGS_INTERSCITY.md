# 📊 Monitoramento de Logs do InterSCity

Este documento explica como monitorar a comunicação com o InterSCity em tempo real.

## 🚀 Logs Implementados

### **Middleware Service (Porta 8081)**
- **Tags:** `[INTERSCITY]`, `[MIDDLEWARE]`
- **Funcionalidades monitoradas:**
  - Configuração de produtores InterSCity
  - Envio de mensagens para InterSCity Adapter
  - Configuração de recursos RabbitMQ
  - Conexão de produtores

### **InterSCity Adapter Service (Porta 8083)**
- **Tags:** `[INTERSCITY ADAPTER]`, `[INTERSCITY SERVICE]`
- **Funcionalidades monitoradas:**
  - Recebimento de mensagens do Middleware
  - Processamento de dados
  - Comunicação com API InterSCity
  - Respostas e erros da API

### **RabbitMQ**
- **Funcionalidades monitoradas:**
  - Criação de filas e exchanges
  - Bindings
  - Tráfego de mensagens

## 🛠️ Como Usar

### **Opção 1: Script Automatizado (Recomendado)**

```bash
# Executar o script de monitoramento
./monitor-intercity-logs.sh
```

O script oferece as seguintes opções:
1. **Monitorar logs do Middleware Service**
2. **Monitorar logs do InterSCity Adapter Service**
3. **Monitorar logs do RabbitMQ**
4. **Monitorar todos os logs simultaneamente** ⭐
5. **Verificar status dos containers**
6. **Sair**

### **Opção 2: Comandos Manuais**

```bash
# Verificar se os containers estão rodando
docker ps | grep dtm

# Logs do Middleware Service (InterSCity)
docker logs -f dtm-middleware 2>&1 | grep -E "\[INTERSCITY\]|\[MIDDLEWARE\]" --color=always

# Logs do InterSCity Adapter Service
docker logs -f dtm-interscity-adapter 2>&1 | grep -E "\[INTERSCITY|\[INTERSCITY ADAPTER\]|\[INTERSCITY SERVICE\]" --color=always

# Logs do RabbitMQ
docker logs -f dtm-rabbitmq 2>&1 | grep -E "channel|queue|exchange|binding" --color=always
```

## 📋 Exemplo de Fluxo de Logs

### **1. Configuração de Produtor InterSCity**
```
🚀 [MIDDLEWARE] Iniciando Middleware Service...
✅ [MIDDLEWARE] Middleware Service iniciado com sucesso!

⚙️ [INTERSCITY] Configurando produtor prod-123 para InterSCity Adapter...
🔧 [INTERSCITY] Configurando recursos RabbitMQ para InterSCity Adapter...
📋 [INTERSCITY] Fila declarada: interscity.adapter.queue
📋 [INTERSCITY] Exchange declarado: interscity.adapter.exchange
📋 [INTERSCITY] Binding configurado: interscity.adapter.key
✅ [INTERSCITY] Recursos RabbitMQ para InterSCity Adapter configurados com sucesso!
✅ [INTERSCITY] Produtor prod-123 configurado para InterSCity Adapter!
```

### **2. Envio de Mensagem**
```
🚀 [INTERSCITY] Iniciando envio para InterSCity Adapter...
📋 [INTERSCITY] Producer ID: prod-123
📋 [INTERSCITY] Message ID: 550e8400-e29b-41d4-a716-446655440000
📋 [INTERSCITY] Data: {"temperature": 25.5, "humidity": 60}
📋 [INTERSCITY] Headers: {"sensor_id": "sensor-001"}
📤 [INTERSCITY] Enviando para RabbitMQ - Exchange: interscity.adapter.exchange
📤 [INTERSCITY] Routing Key: interscity.adapter.key
📤 [INTERSCITY] Payload JSON: {"messageId":"550e8400-e29b-41d4-a716-446655440000","data":"{\"temperature\": 25.5, \"humidity\": 60}","customHeaders":{"sensor_id":"sensor-001"}}
✅ [INTERSCITY] Mensagem enviada com sucesso para InterSCity Adapter via RabbitMQ: 550e8400-e29b-41d4-a716-446655440000
```

### **3. Recebimento no InterSCity Adapter**
```
🔄 [INTERSCITY ADAPTER] =====================================================
📥 [INTERSCITY ADAPTER] MENSAGEM RECEBIDA DO MIDDLEWARE!
📋 [INTERSCITY ADAPTER] Fila: queue.tasks.new
📋 [INTERSCITY ADAPTER] Exchange: exchange.direct.tasks
📋 [INTERSCITY ADAPTER] Routing Key: queue.tasks.new
📋 [INTERSCITY ADAPTER] Payload recebido: {"messageId":"550e8400-e29b-41d4-a716-446655440000","data":"{\"temperature\": 25.5, \"humidity\": 60}","customHeaders":{"sensor_id":"sensor-001"}}
🚀 [INTERSCITY ADAPTER] Iniciando processamento para InterSCity...
```

### **4. Comunicação com InterSCity**
```
🌐 [INTERSCITY SERVICE] Iniciando comunicação com InterSCity...
📋 [INTERSCITY SERVICE] Message ID: 550e8400-e29b-41d4-a716-446655440000
📋 [INTERSCITY SERVICE] Data extraída: {"temperature": 25.5, "humidity": 60}
📋 [INTERSCITY SERVICE] Headers: {"sensor_id":"sensor-001"}
🌐 [INTERSCITY SERVICE] URL da API InterSCity: https://cidadesinteligentes.lsdi.ufma.br/interscity_lh
🌐 [INTERSCITY SERVICE] Endpoint completo: https://cidadesinteligentes.lsdi.ufma.br/interscity_lh/catalog/resources
📤 [INTERSCITY SERVICE] Método: POST
📤 [INTERSCITY SERVICE] Headers: {Content-Type=[application/json]}
📤 [INTERSCITY SERVICE] Payload para InterSCity: {"data": {"temperature": 25.5, "humidity": 60}}
🔄 [INTERSCITY SERVICE] Enviando requisição para InterSCity...
✅ [INTERSCITY SERVICE] Resposta recebida do InterSCity!
📥 [INTERSCITY SERVICE] Status: 200 OK
📥 [INTERSCITY SERVICE] Response: {"status":"success","resource_id":"12345"}
✅ [INTERSCITY ADAPTER] Mensagem processada com sucesso!
🔄 [INTERSCITY ADAPTER] =====================================================
```

## 🔍 Troubleshooting

### **Problemas Comuns:**

1. **Container não está rodando:**
   ```bash
   docker ps | grep dtm
   # Se não aparecer, inicie os serviços:
   docker-compose up -d
   ```

2. **Logs não aparecem:**
   ```bash
   # Verifique se há mensagens sendo enviadas
   docker logs dtm-middleware | tail -20
   ```

3. **Erro de conexão com InterSCity:**
   ```bash
   # Verifique a URL da API
   docker logs dtm-interscity-adapter | grep "INTERSCITY_API_URL"
   ```

### **Comandos Úteis:**

```bash
# Ver todos os logs de um container
docker logs dtm-middleware

# Ver logs das últimas 50 linhas
docker logs --tail 50 dtm-interscity-adapter

# Ver logs com timestamp
docker logs -t dtm-rabbitmq

# Limpar logs antigos
docker system prune -f
```

## 📝 Notas Importantes

- Os logs usam **emojis e tags** para facilitar a identificação
- **Verde (✅)** = Sucesso
- **Vermelho (❌)** = Erro
- **Azul (📋)** = Informação
- **Amarelo (⚠️)** = Aviso
- **Roxo (🔄)** = Processamento

- O script de monitoramento filtra automaticamente os logs relevantes
- Use **Ctrl+C** para parar o monitoramento em tempo real
- Os logs são persistidos nos containers Docker 