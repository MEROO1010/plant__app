<?php

namespace App\Policies;

use App\Models\CareLog;
use App\Models\User;

class CareLogPolicy
{
    public function view(User $user, CareLog $log): bool { return $user->id === $log->user_id; }
}
