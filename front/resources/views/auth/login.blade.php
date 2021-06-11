@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header "><h1 class="title monda">{{ __('Login') }}</h1></div>

                <div class="card-body">
                    <form method="POST" action="{{ route('login') }}">
                        @csrf
                        <div class="login">
                            <label for="email" class="label">{{ __('E-Mail Address') }}</label>

                            <div class="">
                                <input id="email" type="email" class="input{{ $errors->has('email') ? ' is-danger' : '' }}" style="width:50%" name="email" value="{{ old('email') }}" required autofocus>

                                @if ($errors->has('email'))
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $errors->first('email') }}</strong>
                                    </span>
                                @endif
                            </div>
                        </div>

                        <div class="login">
                            <label for="password" class="label">{{ __('Password') }}</label>

                            <div>
                                <input id="password" type="password" class="input{{ $errors->has('password') ? ' is-danger' : '' }}" style="width:50%" name="password" required>

                                @if ($errors->has('password'))
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $errors->first('password') }}</strong>
                                    </span>
                                @endif
                            </div>
                        </div>

                        <div class="login">
                            <div>
                                <div>
                                    <label class="checkbox" for="remember">
                                    <input type="checkbox" name="remember" id="remember" {{ old('remember') ? 'checked' : '' }}> {{ __('Remember Me') }}
                                    </label>
                                </div>
                            </div>
                        </div>

                        <div class="login">
                            <div class="">
                                <button type="submit" class="button is-primary">
                                    {{ __('Login') }}
                                </button>

                                @if (Route::has('password.request'))
                                    <a class="link" href="{{ route('password.request') }}">
                                        {{ __('Forgot Your Password?') }}
                                    </a>
                                @endif
                            </div>
                        </div>
                        <div>&nbsp;</div>
                    </form>
                </div>
                
            </div>
        </div>
    </div>
</div>
@endsection
