# go-buf-github-actions-example

Example on how to use [protoc](https://github.com/protocolbuffers/protobuf), 
[buf](https://github.com/bufbuild/buf) and [github actions](https://docs.github.com/en/actions) to create a nice workflow to work with GRPC.

## What it's shown

- compile protobuf files to go using protoc
- contracts lint and breaking changes using buf
- github actions to run the flows mentioned above on every push or pull request

## How to I run this locally?

Run `make` to download dependencies, compile protobuf files, run lint and breaking changes on the latter.