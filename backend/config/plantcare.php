<?php

return [
    // Plant categories are shared across users, so only these accounts may create/edit/delete them.
    // Comma-separated emails in .env, e.g. PLANTCARE_CATEGORY_ADMINS=demo@plantcare.test
    'category_admin_emails' => array_values(array_filter(array_map('trim', explode(',', env('PLANTCARE_CATEGORY_ADMINS', ''))))),
];
