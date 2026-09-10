package main

import (
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/example/lambda-cicd-demo/internal/handler"
)

func main() {
	lambda.Start(handler.Handle)
}
