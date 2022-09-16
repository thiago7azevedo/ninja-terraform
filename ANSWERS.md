## Saudações
Prezados, obrigado pela oportunidade em realizar o teste da Get Ninjas, para o cargo de Devops. Foi de fato um baita desafio, pude mergulhar ainda mais em aprimoramento, aprendizado e disciplina.

## Descrição
Bem, seguindo com as questões, utilizei o Terraform para criação da IA, onde subi toda a infra em uma conta pessoal na AWS. Após a estrutura estar pronta com o primeiro Deploy, utilzei o Actions do próprio Github para prover os testes e a integração continua necessária para maior eficiência desde o desenvolimento até a produção. 

Neste teste, decidi fugir um pouco da minha zona de conforto. Entendi que subir a aplicação em simples docker em uma instância de EC2, atrás de um reverso como NGINX por exemplo, seria bastante simplório pelo nível técnico do teste. 

Pensando nisso, segui na linha de subir um cluster ECS com FARGATE, de modo que ganhamos em escalabilidade, pois podemos subir rapidadmente réplicas do mesmo container, monitoramento e logs (CloudWatch). Sobre a escolha pelo FARGATE, foi visando exatamente a simplicidade de não precisar lhe dar com a criação e gerenciamento de instâncias EC2, deixando a própria AWS gerenciar esta parte.

Além disso, visando a segurança do cluster ECS e de todos os componentes, criei um Security Group com restrições, atrelando também as regras de IAM.
Outro ponto importante foi a criação de um LB também em forma de código, onde podemos poesteriormente utilizar um certificado SSL gerdo pela própria AWS de forma gratuita, devido ao uso do LB.

Sendo assim, creio cumprido com a entrega de todos os requisitos, onde fico à disposição para qualquer dúvida ou sugestão.

## Pré-requisitos
- Install [Terraform v1.2.9](https://www.terraform.io/cli/install/apt)
- Install [Go v1.18](https://go.dev/dl/go1.18beta1.linux-amd64.tar.gz)
- Account in DockerHub [Docker](https://docs.docker.com/engine/install/ubuntu/)
- Account in DockerHub [DockeeHub](https://hub.docker.com/)

## Build da imagem
Utilizei um Dockerfile para a montagem da imagem através do código em GOLANG fornecido. Neste arquivo, setei o scratch para diminuir o tamanho da imagem gerada em GO e expus a porta 8000 conforme a aplicação pede.

OBS: Para efetuar o build na sua conta local, alterar o usuário e patch.
`docker image build -t thiago7azeveo/devops-ninja:latest .`

`docker tag aa8989cebde0 thiago7azeveo/devops-ninja:latest`

## Push para DockerHub
Após o Build da imagem, efetuei o login na minha conta do docker hub, gerando uma tag e mandei a imagem para o repositório remoto.

`docker login -u USÁRIO -p SENHA`

`docker image push thiago7azeveo/devops-ninja:latest`

## Código em Terraform para deploy em ECS
A montagem da infraestrutura necessária para subir a imagem criada na AWS, foi bastante interessante pelas formas que existem. EKS, EC2, LB ou ECS, esta ultima acabou sendo minha escolha pelo fato de poder entregar escalabilidade, segurança e facilidade de gerenciamento.

Procurei deixar o código o mais limpo possível, onde segmentei o `remote_state`, `ecs` e `modules`. 

Para poder fazer o deploy de toda a infra, é necessário seguir os seguintes passsos:

1. Na raiz do projeto, `cd infra/devops/remote_state` e rodar `terraform apply -lock=false --auto-approve`
    - OBS: No remote state existe o códifo para criação do bucket S3 onde vai ficar o arquivo terraform.tfstate, que guarda o estado remoto do cluster, afim de ser compartilhado com a equipe, para trabalhos simuntâneos. 
2. Ainda na raiz do projeto, `cd infra/devops/ecs` e rodar `terraform apply -lock=false --auto-approve`
3. Seguindo a premissa de que os passos 1 e 2 foram criados corretamente, é necessário novamente efetuar o deploy do ecs, afim de habilitar a task `terraform apply -var="release_version=1" -lock=false --auto-approve`

## CI/CD Github Actions
Após a subida com sucesso de toda a infra nos passos anteriores, finalizo a entrega do teste com um Action no github, onde a partir de um push, pull ou create, efetua o teste da aplicação em GO, bem como o deploy automático do container no ECS da AWS. 
Em tempo, são necessários o cadastramento dos secrets actions no settings do projeto: `AWS_ACCESS_KEY_ID`, `AWS_REGION`, `AWS_SECRET_ACCESS_KEY`, `DOCKERHUB_TOKEN` e `DOCKERHUB_USERNAME`.

Segue link com a URL do Build efetuado com sucesso:
[![Teste e Deploy para Amazon ECS](https://github.com/thiago7azevedo/ninja-terraform/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/thiago7azevedo/ninja-terraform/actions/workflows/ci-cd.yml)


Para a resposta da a questão de como alterar o nome da aplicação de Ninja para outro nome. Com o projeto no repositório local ou no remoto, é necessário efetuar a alteração do arquivo `main.go` na linha 19 `appname := getEnv("APP_NAME", "Ninja")` modificando a entrada para a variável `APP_NAME`. 
Após a mudança e com o devido commit efetuado, automativamente será gerado uma nova imagem com a alteração efetuada, subindo direto como uma task no cluster ECS e ficando disponível para acesso no endereço: [Aplicação Teste Devops Get Ninja](http://devops-ninja-lb-devops-1138630858.us-east-1.elb.amazonaws.com/healthcheck).
OBS: a Branch utilizada para a entrega continua é a master, para evitar que outras branches corrompidas quebrem o código e a aplicação.


Segue nova saída do curl:
```
➜  ninja-terraform git:(master) ✗ curl -i http://devops-ninja-lb-devops-1138630858.us-east-1.elb.amazonaws.com/healthcheck
HTTP/1.1 200 OK
Date: Fri, 16 Sep 2022 07:09:55 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 24
Connection: keep-alive

Hey Bro, Jesus is Alive!%
```