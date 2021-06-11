@extends('layouts.app')
@section('content')
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header">
                    <h1 class="title monda">{{ __('Change Password') }}</h1>
                    </div>

                    <div class="card-body">
                        <form class="form-horizontal" method="POST" action="{{ route('changePassword') }}">
                            {{ csrf_field() }}

                            <div class="login {{ $errors->has('current-password') ? ' has-error' : '' }}">
                                <label for="new-password" class="label">Current Password</label>

                                <div class="col-md-6">
                                    <input id="current-password" type="password" class="input" style="width:50%" name="current-password" required>

                                    @if ($errors->has('current-password'))
                                        <span class="help-block">
                                        <strong>{{ $errors->first('current-password') }}</strong>
                                    </span>
                                    @endif
                                </div>
                            </div>

                            <div class="login {{ $errors->has('new-password') ? ' has-error' : '' }}">
                                <label for="new-password" class="label">New Password</label>

                                <div class="col-md-6">
                                    <input id="new-password" type="password" class="input" style="width:50%" name="new-password" required>

                                    @if ($errors->has('new-password'))
                                        <span class="help-block">
                                        <strong>{{ $errors->first('new-password') }}</strong>
                                    </span>
                                    @endif
                                </div>
                            </div>

                            <div class="login">
                                <label for="new-password-confirm" class="label">Confirm New Password</label>

                                <div class="col-md-6">
                                    <input id="new-password-confirm" type="password" class="input" style="width:50%" name="new-password_confirmation" required>
                                </div>
                            </div>

                            <div class="login">
                                <div class="col-md-6 col-md-offset-4">
                                    <button type="submit" class="button is-primary">
                                        Change Password
                                    </button>
                                </div>
                            </div>
                            @if (session('error'))
                            <div>&nbsp;</div>
                            <div class="notification has-text-centered is-danger">
                                {{ session('error') }}
                            </div>
                            @endif
                            @if (session('success'))
                                <div>&nbsp;</div>
                                <div class="notification has-text-centered is-success">
                                    {{ session('success') }}
                                </div>
                            @endif
                            <div>&nbsp;</div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection
