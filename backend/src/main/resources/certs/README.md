# Local RSA keys

This directory is intentionally empty. The `dev`, `local`, and `test` profiles generate an ephemeral
keypair when key locations are unset, so tokens stop working after an application restart.

To keep local tokens across restarts, generate uncommitted PKCS#8 keys:

```bash
openssl genrsa -out keypair.pem 2048
openssl rsa -in keypair.pem -pubout -out public-key.pem
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in keypair.pem -out private-key.pem
rm keypair.pem
```

Set `RSA_PUBLIC_KEY=classpath:certs/public-key.pem` and
`RSA_PRIVATE_KEY=classpath:certs/private-key.pem`. Never commit private keys.
