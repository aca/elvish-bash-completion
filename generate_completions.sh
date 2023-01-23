#!/bin/sh

kubectl completion bash > completions/kubectl.bash
gh completion -s bash > ./completions/gh
pueue completions bash ./completions
