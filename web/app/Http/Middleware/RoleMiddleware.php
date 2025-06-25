<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     * @param  mixed ...$roles
     * @return \Symfony\Component\HttpFoundation\Response
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        if (!Auth::check()) {
            if ($request->expectsJson()) {
                return response()->json(['error' => 'Please login first'], 403);
            }
            return redirect()->route('login');
        }

        if (in_array(Auth::user()->role, $roles)) {
            return $next($request);
        }

        if ($request->expectsJson()) {
            return response()->json(['error' => 'Forbidden: You do not have the required permissions'], 403);
        }

        abort(403, 'Forbidden');
    }
}
