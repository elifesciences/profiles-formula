profiles:
    oauth_clients:
        some-app:
            client_id: foo
            client_secret: bar
            redirect_uris:
                - https://example.com/check
                - https://testing.example.com/check
    orcid:
        api_uri: http://localhost:8001
        authorize_uri: http://localhost:8001/oauth2/authorize
        token_uri: http://localhost:8001/oauth2/token
        client_id: null
        client_secret: null
        read_public_access_token: null
        webhook_access_token: null
        webhook_key: null
    default_host: localhost
    default_scheme: http
    db:
        name: profiles
        username: foouser # case sensitive. use all lowercase
        password: barpass
        host: host.docker.internal
        port: 5432
    logging:
        level: DEBUG
    sns:
        name: bus-profiles
        subscriber: null
        region: us-east-1
        # TODO: add optional goaws endpoint_url
    consumer_groups_filter:
        api_gateway:
            username: api-gateway
            password: some-credentials

elife:
    aws:
        access_key_id: AKIAFAKE
        secret_access_key: fake
    sidecars:
        main: elifesciences/profiles
        containers:
            orcid_dummy:
                name: orcid-dummy
                image: elifesciences/orcid-dummy
                port: 8001
                enabled: true
    goaws:
        host: goaws
        topics:
            - profiles--dev

