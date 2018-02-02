profiles:
    oauth_clients:
        some-app:
            client_id: foo
            client_secret: bar
            redirect_uri: https://example.com/check
    orcid:
        api_uri: http://localhost:8081
        authorize_uri: http://localhost:8081/oauth2/authorize
        token_uri: http://localhost:8081/oauth2/token
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
        host: 127.0.0.1
        port: 5432
    logging:
        level: DEBUG
    sns:
        name: bus-profiles
        subscriber: null
        region: us-east-1

elife:
    aws:
        access_key_id: AKIAFAKE
        secret_access_key: fake
    uwsgi:
        services:
            profiles:
                folder: /srv/profiles
    newrelic_python:
        application_folder: /srv/profiles
        service: # blank as always restarted
        dependency_state: profiles-install
    coveralls:
        tokens:
            profiles: somefaketoken
    php_dummies:
        orcid_dummy:
            repository: https://github.com/elifesciences/orcid-dummy
            pinned_revision_file: /srv/profiles/orcid-dummy.sha1
            port: 8081  # 8082 for https

