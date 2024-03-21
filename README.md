# Módulo Start Stop

Realiza o start/stop dos recursos no horário especificado. É preciso incluir a tag definida no módulo nos recursos que devem ser incluídos na rotina.

Padrão CRON utilizado: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-cron-expressions.html

## Parâmetros do Módulo

| Parâmetro         | Opcional | Descrição                                                                                                                                               |
|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| `region`          | | Região AWS na qual as configurações se aplicarão (por exemplo, "us-east-1").                                                                              |
| `start_cron`      | | Expressão de cron para o horário de início dos recursos.                                                                                                  |
| `stop_cron`       | | Expressão de cron para o horário de parada dos recursos.                                                                                                  |
| `manual_endpoint` | Sim | Se for true, realiza a criação de um API Gateway com dois endpoints **/start** e **/stop.** Invocar esses endpoints via POST tem o mesmo efeito que as ações executadas nos horários das CRONs. Para invocar esses endpoints, é necessário incluir a API Key que é criada junto do API Gateway. Essa chave pode ser resgatada a partir do console ou CLI.                                                                            |
| `tag`             | | Bloco para especificar a tag que identifica quais recursos devem ser afetados pelo start-stop                                                                        |
| `ecs`             | Sim | Se for true, Services do ECS que possuírem a tag serão incluídos no start-stop. Isso é feito setando o Desired Count para 0.                                                                  |
| `rds`             | Sim | Se for true, instâncias RDS e Aurora que possuírem a tag serão incluídos no start-stop. Isso é feito a partir do desligamento das instâncias.                                                                  |
| `ec2`             | Sim | Se for true, instâncias EC2 que possuírem a tag serão incluídos no start-stop. Isso é feito a partir do desligamento das instâncias.                                                     |
| `asg`             | Sim | Se for true, ASG que possuírem a tag serão incluídos no start-stop. Não é necessário incluir a tag de start-stop nas instâncias EC2 que pertencerem ao ASG. Isso é feito setando o Desired Count para 0. |

## Como funciona

### TODO: Detalhar
EventBridge/API Gateway => SNS => Lambda => EC2/ECS/RDS