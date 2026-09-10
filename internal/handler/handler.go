// Package handler implements the Lambda business logic behind an API Gateway proxy integration.
package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
)

// Response is the JSON payload returned by the handler.
type Response struct {
	Message   string `json:"message"`
	Version   string `json:"version"`
	Timestamp string `json:"timestamp"`
}

// Handle processes an API Gateway proxy request and returns a proxy response.
func Handle(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	version := os.Getenv("APP_VERSION")
	if version == "" {
		version = "dev"
	}

	body := Response{
		Message:   fmt.Sprintf("hello from lambda, path=%s", req.Path),
		Version:   version,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	payload, err := json.Marshal(body)
	if err != nil {
		return events.APIGatewayProxyResponse{StatusCode: 500}, err
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers:    map[string]string{"Content-Type": "application/json"},
		Body:       string(payload),
	}, nil
}
