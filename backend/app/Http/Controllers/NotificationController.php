<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(): JsonResponse
    {
        $notifications = Notification::with('user')
            ->latest()
            ->take(10)
            ->get()
            ->map(function ($notification) {
                return [
                    'id' => $notification->id,
                    'type' => $notification->type,
                    'title' => $notification->title,
                    'message' => $notification->message,
                    'is_read' => $notification->is_read,
                    'created_at' => $notification->created_at->diffForHumans(),
                    'data' => $notification->data
                ];
            });

        $unreadCount = Notification::unread()->count();

        return response()->json([
            'notifications' => $notifications,
            'unread_count' => $unreadCount
        ]);
    }

    public function markAsRead(Request $request): JsonResponse
    {
        $notification = Notification::findOrFail($request->notification_id);
        $notification->markAsRead();

        return response()->json(['message' => 'Notifikasi telah ditandai sebagai dibaca']);
    }

    public function markAllAsRead(): JsonResponse
    {
        Notification::unread()->update(['is_read' => true]);

        return response()->json(['message' => 'Semua notifikasi telah ditandai sebagai dibaca']);
    }
}