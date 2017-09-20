profiles:
    oauth_clients:
        some-app:
            client_id: foo
            client_secret: bar
            redirect_uri: https://example.com/check
    orcid:
        authorize_uri: https://orcid.org/oauth/authorize
        token_uri: https://orcid.org/oauth/token
        client_id: null
        client_secret: null
    default_host: localhost
    db:
        name: profiles
        username: foouser # case sensitive. use all lowercase
        password: barpass
        host: 127.0.0.1
        port: 5432
    logging:
        level: DEBUG
    orcid_dummy:
        pinned_revision_file: /srv/profiles/orcid-dummy.sha1
