FROM golang:1.18 as builder
WORKDIR /app
COPY . .
# "CGO_ENABLED=0" : Alguns serviços precisam da Lib C, por isso CGO setado.
# "GOOS=linux" : Importante passar o SO para evitar problemas de compatível.
# "GOARCH=amd64" : Arquitetura para evitar problemas de compatível.
RUN CGO_ENABLED=0 DOOS=linux GOARCH=amd64 go build -o server

### scratch setado para diminuir o tamanho da imagem gerada anteriormente.
FROM scratch 
COPY --from=builder /app/server /server
ENTRYPOINT [ "/server" ]
EXPOSE 8000/tcp