<?php

namespace App\Services;

use App\Http\Resources\PlantResource;
use App\Http\Resources\ReminderResource;
use App\Models\CareLog;
use App\Models\Plant;
use App\Models\Reminder;
use App\Models\User;

class StatisticsService
{
    public function __construct(private ReminderService $reminders) {}

    public function dashboard(User $user): array
    {
        $today = $this->reminders->today($user);

        // Featured plant: critical/needs-attention first, then the most overdue watering.
        $featured = Plant::with('category')->where('user_id', $user->id)
            ->where(fn ($q) => $q->where('health_status', '!=', 'healthy')->orWhere('next_watering_at', '<=', now()))
            ->orderByRaw("CASE health_status WHEN 'critical' THEN 0 WHEN 'needs_attention' THEN 1 ELSE 2 END")
            ->orderBy('next_watering_at')
            ->first();

        return [
            'total_plants' => Plant::where('user_id', $user->id)->count(),
            'tasks_due_today' => $today->count(),
            'overdue_tasks' => $today->filter(fn ($r) => $r->due_at->lt(now()->startOfDay()))->count(),
            'weekly_progress' => $this->weeklyProgress($user),
            'featured_plant' => $featured ? (new PlantResource($featured))->resolve(request()) : null,
            'today_reminders' => ReminderResource::collection($today)->resolve(request()),
            'upcoming_reminders' => ReminderResource::collection($this->reminders->upcoming($user)->take(5))->resolve(request()),
        ];
    }

    /** Current week (Mon–Sun): reminders due vs completed per day, plus care actions logged. */
    public function weeklyProgress(User $user): array
    {
        $start = now()->startOfWeek();
        $days = [];
        $totalDue = 0;
        $totalDone = 0;

        for ($i = 0; $i < 7; $i++) {
            $day = $start->copy()->addDays($i);
            $due = Reminder::where('user_id', $user->id)->whereBetween('due_at', [$day->copy()->startOfDay(), $day->copy()->endOfDay()]);
            $dueCount = (clone $due)->count();
            $doneCount = (clone $due)->where('is_completed', true)->count();
            $logs = CareLog::where('user_id', $user->id)->whereBetween('performed_at', [$day->copy()->startOfDay(), $day->copy()->endOfDay()])->count();

            $totalDue += $dueCount;
            $totalDone += $doneCount;
            $days[] = [
                'date' => $day->toDateString(),
                'day' => $day->format('D'),
                'tasks_due' => $dueCount,
                'tasks_completed' => $doneCount,
                'care_actions' => $logs,
            ];
        }

        return [
            'week_start' => $start->toDateString(),
            'week_end' => $start->copy()->endOfWeek()->toDateString(),
            'tasks_due' => $totalDue,
            'tasks_completed' => $totalDone,
            'completion_percentage' => $totalDue > 0 ? (int) round($totalDone / $totalDue * 100) : 0,
            'days' => $days,
        ];
    }

    public function plantHealth(User $user): array
    {
        $counts = Plant::where('user_id', $user->id)->selectRaw('health_status, COUNT(*) as total')
            ->groupBy('health_status')->pluck('total', 'health_status');

        $breakdown = [];
        foreach (Plant::HEALTH_STATUSES as $status) {
            $breakdown[$status] = (int) ($counts[$status] ?? 0);
        }
        $total = array_sum($breakdown);

        return [
            'total' => $total,
            'breakdown' => $breakdown,
            'healthy_percentage' => $total > 0 ? (int) round($breakdown['healthy'] / $total * 100) : 0,
            'overdue_watering' => Plant::where('user_id', $user->id)->where('next_watering_at', '<', now())->count(),
        ];
    }
}
