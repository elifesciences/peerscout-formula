You will need to create the file `salt/pillar/peerscout-secrets` to use this formula locally, e.g. with the following contents:

```salt
peerscout:
    aws:
        access_key_id: <access key>
        secret_access_key: <secret>
```
