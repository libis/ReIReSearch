<?php

namespace App\Http\Controllers;
use Hash;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\User;

class UserController extends Controller
{
    //
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function edit()
    {   
        $user = Auth::user();
        return view('users.edit', compact('user'));
    }

    public function update()
    { 
        $user = Auth::user();
        $this->validate(request(), [
                'name' => 'required',
                'email' => 'required|email',
            ]);

        $user->name = request('name');
        $user->email = request('email');
        $user->brepolsid = request('brepolsid');

        $user->save();
        
        return redirect('/');  
    }
    
    public function delete() {
        $user = Auth::user();
        
        foreach ($user->eshelfs as $eshelf) {
            foreach ($eshelf->items as $item) $item->delete();
            $eshelf->delete();
        }
        $user->delete();

        return redirect('/logout');
    }

    public function showChangePasswordForm(){
        return view('auth.changepassword');
    }

    public function changePassword(Request $request){
        if (!(Hash::check($request->get('current-password'), Auth::user()->password))) {
            // The passwords matches
            return redirect()->back()->with("error","Your current password does not match with the password you provided. Please try again.");
        }
        if(strcmp($request->get('current-password'), $request->get('new-password')) == 0){
            //Current password and new password are same
            return redirect()->back()->with("error","New Password cannot be same as your current password. Please choose a different password.");
        }
        $validatedData = $request->validate([
            'current-password' => 'required',
            'new-password' => 'required|string|min:6|confirmed',
        ]);
        //Change Password
        $user = Auth::user();
        $user->password = bcrypt($request->get('new-password'));
        $user->save();
        return redirect()->back()->with("success","Password changed successfully !");
    }
}
