@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header"><h1 class="title monda">{{ __('Profile') }}</h1></div>

                <div class="card-body">


                    <form method="post" action="{{route('profile.update')}}">
                        {{ csrf_field() }}
                        {{ method_field('patch') }}
                        <div class="login">
                            <label for="name" class="label">{{ __('Name') }}</label>

                            <div class="">
                                <input id="name" type="text" class="input{{ $errors->has('name') ? ' is-invalid' : '' }}" style="width:50%" name="name" value="{{ $user->name }}" required autofocus>

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
                                <input id="email" type="email" class="input{{ $errors->has('email') ? ' is-invalid' : '' }}" style="width:50%" name="email" value="{{ $user->email }}" required>

                                @if ($errors->has('email'))
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $errors->first('email') }}</strong>
                                    </span>
                                @endif
                            </div>
                        </div>
                        <div class="login">
                            <label for="brepolsid" class="label">{{ __('Brepols user token') }}</label>

                            <div class="">
                                <input id="brepolsid" type="brepolsid" class="input{{ $errors->has('brepolsid') ? ' is-invalid' : '' }}" style="width:50%" name="brepolsid" value="{{ $user->brepolsid }}">

                                @if ($errors->has('brepolsid'))
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $errors->first('brepolsid') }}</strong>
                                    </span>
                                @endif
                            </div>
                        </div>


                        <div class="login">
                            <div class="">
                                <button type="submit" class="button is-primary">
                                    {{ __('Save profile') }}
                                </button>
                                <a class="button" href="{{ route('profile.changepassword') }}">
                                    {{ __('Change password') }}
                                </a>
                                <button type="button" class="button" onClick="if (confirm('Are you sure you wish to delete this profile.\nAll stored information will be erased.\nRecovery is not possible.')) document.location='/profile/delete'">
                                    {{ __('Delete profile') }}
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