@extends('layouts.app')

@section('content')
<div class="container">
    <div class="">
        <div class="">
            <div class="card">
                <div class="card-header"><h1 class="title monda">{{ __('Register') }}</h1></div>

                <div class="card-body">
                    <form method="POST" action="{{ route('register') }}">
                        @csrf

                        <div class="login">
                            <label for="name" class="label">{{ __('Name') }}</label>

                            <div class="">
                                <input id="name" type="text" class="input{{ $errors->has('name') ? ' is-danger' : '' }}" style="width:50%" name="name" value="{{ old('name') }}" required autofocus>

                                @if ($errors->has('name'))
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $errors->first('name') }}</strong>
                                    </span>
                                @endif
                            </div>
                        </div>

                        <div class="login">
                            <label for="email" class="label">{{ __('E-Mail Address') }}</label>

                            <div class="">
                                <input id="email" type="email" class="input{{ $errors->has('email') ? ' is-danger' : '' }}" style="width:50%" name="email" value="{{ old('email') }}" required>

                                @if ($errors->has('email'))
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $errors->first('email') }}</strong>
                                    </span>
                                @endif
                            </div>
                        </div>

                        <div class="login">
                            <label for="password" class="label">{{ __('Password') }}</label>

                            <div class="">
                                <input id="password" type="password" class="input{{ $errors->has('password') ? ' is-danger' : '' }}" style="width:50%" name="password" required>

                                @if ($errors->has('password'))
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $errors->first('password') }}</strong>
                                    </span>
                                @endif
                            </div>
                        </div>

                        <div class="login">
                            <label for="password-confirm" class="label">{{ __('Confirm Password') }}</label>

                            <div class="">
                                <input id="password-confirm" type="password" class="input" style="width:50%" name="password_confirmation" required>
                            </div>
                        </div>

                        <div class="login">
                            

                            <div class="">
                                <label for="tos_signed" class="checkbox"><input id="tos_signed" type="checkbox" class="form-control" name="tos_signed" required value="1"> I have read and agree to the <a href="{{ route('tos') }}">Terms Of Service</a></label>
                            </div>
                        </div>


                        <div class="login">
                            <div class="">
                                <button type="submit" class="button is-primary">
                                    {{ __('Register') }}
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
