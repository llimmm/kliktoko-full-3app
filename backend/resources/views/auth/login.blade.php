<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>KlikToko - Masuk Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    {{-- Halaman ini berdiri sendiri: admin.css TIDAK dimuat di sini.
         Hanya variabel dari tokens.css dan kelas Bootstrap yang boleh dipakai. --}}
    <link href="{{ asset('css/tokens.css') }}?v={{ filemtime(public_path('css/tokens.css')) }}" rel="stylesheet">
    <style>
        body {
            min-height: 100vh;
            margin: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
            background: var(--neutral-50);
            color: var(--text-primary);
            font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', sans-serif;
        }

        .login-shell {
            width: 100%;
            max-width: 400px;
        }

        .login-card {
            background: var(--neutral-0);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-lg);
            padding: 2.5rem 2rem;
        }

        .brand {
            text-align: center;
            margin-bottom: 2rem;
        }

        /* Satu-satunya sapuan warna aksen di halaman ini. */
        .brand-mark {
            width: 3.5rem;
            height: 3.5rem;
            margin: 0 auto 1rem;
            border-radius: var(--border-radius);
            background: var(--violet-600);
            color: var(--neutral-0);
            font-size: 1.375rem;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .brand-name {
            margin: 0;
            font-size: 1.5rem;
            font-weight: 700;
            letter-spacing: -0.02em;
        }

        .brand-sub {
            margin: 0.25rem 0 0;
            font-size: 0.875rem;
            color: var(--text-secondary);
        }

        .form-label {
            font-size: 0.875rem;
            font-weight: 500;
            color: var(--neutral-700);
        }

        .form-control {
            padding: 0.75rem 1rem;
            border-color: var(--border-color);
            border-radius: var(--border-radius-sm);
        }

        .password-field {
            position: relative;
        }

        .password-field .form-control {
            padding-right: 2.75rem;
        }

        .password-toggle {
            position: absolute;
            top: 50%;
            right: 0.25rem;
            transform: translateY(-50%);
            width: 2.25rem;
            height: 2.25rem;
            display: flex;
            align-items: center;
            justify-content: center;
            background: none;
            border: 0;
            border-radius: var(--border-radius-sm);
            color: var(--text-secondary);
            cursor: pointer;
        }

        .password-toggle:hover {
            color: var(--text-primary);
        }

        .btn-masuk {
            width: 100%;
            padding: 0.75rem 1rem;
            font-weight: 600;
            border-radius: var(--border-radius-sm);
        }

        .login-foot {
            margin: 1.5rem 0 0;
            text-align: center;
            font-size: 0.8125rem;
            color: var(--text-secondary);
        }
    </style>
</head>
<body>
    <main class="login-shell">
        <div class="login-card">
            <div class="brand">
                <div class="brand-mark">
                    <i class="fas fa-store"></i>
                </div>
                <h1 class="brand-name">KlikToko</h1>
                <p class="brand-sub">Panel Admin</p>
            </div>

            {{-- Middleware admin mengalihkan ke sini dengan pesan ini ketika
                 karyawan atau user nonaktif mencoba masuk panel. Jangan dihapus. --}}
            @if(session('error'))
                <div class="alert alert-danger" role="alert">
                    <i class="fas fa-circle-exclamation me-2"></i>{{ session('error') }}
                </div>
            @endif

            <form action="{{ route('login.post') }}" method="POST">
                @csrf

                <div class="mb-3">
                    <label class="form-label" for="name">Nama Pengguna</label>
                    <input type="text" name="name" id="name" class="form-control"
                           value="{{ old('name') }}" autocomplete="username"
                           placeholder="Masukkan nama pengguna" required autofocus>
                </div>

                <div class="mb-4">
                    <label class="form-label" for="password">Kata Sandi</label>
                    <div class="password-field">
                        <input type="password" name="password" id="password" class="form-control"
                               autocomplete="current-password"
                               placeholder="Masukkan kata sandi" required>
                        <button type="button" class="password-toggle" id="passwordToggle"
                                aria-label="Tampilkan kata sandi">
                            <i class="fas fa-eye" id="password-icon"></i>
                        </button>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary btn-masuk">Masuk</button>
            </form>
        </div>

        <p class="login-foot">Butuh akses? Hubungi administrator toko.</p>
    </main>

    <script>
        document.getElementById('passwordToggle').addEventListener('click', function () {
            const field = document.getElementById('password');
            const icon = document.getElementById('password-icon');
            const shown = field.type === 'text';

            field.type = shown ? 'password' : 'text';
            icon.classList.toggle('fa-eye', shown);
            icon.classList.toggle('fa-eye-slash', !shown);
            this.setAttribute('aria-label', shown ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi');
        });
    </script>
</body>
</html>
