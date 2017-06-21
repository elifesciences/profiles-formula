<?php
return [
    'base_url' => '{{ pillar.profiles.base_url }}',
    'orcid' => [
        'client_id' => '{{ pillar.profiles.orcid.client_id }}',
        'client_secret' => '{{ pillar.profiles.orcid.client_secret }}',
    ],
];
