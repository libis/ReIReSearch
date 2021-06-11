@extends('layouts.app')

@section('content')
<div class="container">
    <div class="">
        <div class="">
            <div class="card">
                <div class="card-header"><h1 class="title monda">{{ __('Reset Password') }}</h1></div>

                <div class="card-body">
                    @if (session('status'))
                        <div class="alert alert-success" role="alert">
                            {{ session('status') }}
                        </div>
                    @endif

                    <form method="POST" action="{{ route('password.email') }}">
                        @csrf

                        <div class="login">
                            <label for="email" class="label">{{ __('E-Mail Address') }}</label>
                            <div class="">
                                <input id="email" type="email" class="input{{ $errors->has('email') ? ' is-danger' : '' }}"  style="width:50%" name="email" value="{{ old('email') }}" required>

                                @if ($errors->has('email'))
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $errors->first('email') }}</strong>
                                    </span>
                                @endif
                            </div>
                        </div>

                        <div class="login">
                            <div class="">
                                <button type="submit" class="button is-primary">
                                    {{ __('Send Password Reset Link') }}
                                </button>
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
