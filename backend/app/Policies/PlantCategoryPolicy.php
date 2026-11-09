<?php

namespace App\Policies;

use App\Models\PlantCategory;
use App\Models\User;

/**
 * Categories are shared by all users: everyone can read them,
 * only accounts listed in PLANTCARE_CATEGORY_ADMINS can change them.
 */
class PlantCategoryPolicy
{
    public function create(User $user): bool { return $this->isAdmin($user); }
    public function update(User $user, PlantCategory $category): bool { return $this->isAdmin($user); }
    public function delete(User $user, PlantCategory $category): bool { return $this->isAdmin($user); }

    private function isAdmin(User $user): bool
    {
        return in_array($user->email, config('plantcare.category_admin_emails', []), true);
    }
}
