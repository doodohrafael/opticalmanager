# Observabilidade

## 1.1. Logs
- **Padrão**: Logs estruturados em JSON.
- **Ferramenta**: [Logback](https://logback.logback.qos.ch/) com [Logstash Logback Encoder](https://github.com/logstash/logstash-logback-encoder).
- **Nível**: Configurar níveis de log apropriados por ambiente (`INFO` para produção, `DEBUG` para desenvolvimento).
- **Campos importantes**: Timestamp, Level, Thread, Logger, Message, MDC (contexto de tenant, user id, request ID).

### 1.2. Métricas
- **Padrão**: Micrometer com Prometheus.
- **Exposição**: Endpoint `/actuator/prometheus`.
- **Tipos**: Counters, Gauges, Timers, Distribution Summaries.
- **Nomenclatura**: Clara e consistente (ex: `http.server.requests`, `jvm.memory.used`, `app.custom.metric.name`).
- **Tags**: Utilizar tags relevantes para filtragem e agregação (ex: `http.status_code`, `app.tenant_id`, `app.user_id`, `app.operation_name`).

### 1.3. Tracing (Rastreamento Distribuído)
- **Ferramenta**: [Micrometer Tracing](https://micrometer.io/docs/tracing) (anteriormente Spring Cloud Sleuth).
- **Contexto**: Propagar IDs de trace e span automaticamente entre serviços/componentes.
- **Exportação**: Configurar exportador para [Zipkin](https://zipkin.io/) ou [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/).

---

## 4. Métricas Customizadas

- **Padrão**: Utilizar [Micrometer](https://micrometer.io/) para instrumentar código.
- **Criação de Métricas**: 
    - **Contadores**: Para somar eventos (ex: número de chamadas a um serviço externo).
    - **Timers**: Para medir durações de operações (ex: tempo de processamento de uma requisição).
    - **Gauges**: Para valores que podem subir e descer (ex: tamanho da fila de processamento).
- **Exemplo de Código (Simplificado)**:
  ```java
  import io.micrometer.core.instrument.Counter;
  import io.micrometer.core.instrument.MeterRegistry;
  import org.springframework.stereotype.Service;

  @Service
  public class MyService {
      private final Counter myCounter;

      public MyService(MeterRegistry meterRegistry) {
          this.myCounter = meterRegistry.counter("my.service.operations.count", "status", "success");
      }

      public void performOperation() {
          // ... opera
          myCounter.increment();
      }
  }
  ```
- **Tags**: Aplicar tags relevantes para segmentar métricas (ex: `operation_name`, `tenant_id`).
