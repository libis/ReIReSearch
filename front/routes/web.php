<?php

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});


Auth::routes();

Route::get('/record/{id}/{format?}','SearchController@record');
Route::post('/cite/{style}/{format}/{mode}','CiteController@cite');

Route::get('/home', 'HomeController@index')->name('home');

Route::resource('eshelf','EshelfController');
Route::resource('item','ItemController');

Route::post('search','SearchController@search');
Route::get('feedback','FeedbackController@index')->name('feedback');
Route::get('history/list','SearchController@history');


Route::get('page/help','PageController@help')->name('help');
Route::get('page/about','PageController@about')->name('about');
Route::get('page/tos','PageController@tos')->name('tos');
Route::get('page/subscriptions','PageController@subscriptions')->name('subscriptions');
Route::get('page/privacy','PageController@privacy')->name('privacy');

Route::get('profile',  ['as' => 'profile.edit', 'uses' => 'UserController@edit']);
Route::patch('profile/update',  ['as' => 'profile.update', 'uses' => 'UserController@update']);
Route::get('profile/delete',  ['as' => 'profile.delete', 'uses' => 'UserController@delete']);
Route::get('profile/changepassword',  ['as' => 'profile.changepassword', 'uses' => 'UserController@showChangePasswordForm']);
Route::post('/changePassword','UserController@changePassword')->name('changePassword');

Route::get('logout', ['as' => 'logout', 'uses' => "Auth\LoginController@logout"]);

Route::post('query/save','QueryController@save');
Route::get('query/list','QueryController@list');
Route::get('query/delete/{id}','QueryController@delete');
Route::post('query/queue', 'QueryController@queue');


Route::post('mail/item', 'MailController@email_item');

Route::get('set/list', "EshelfController@list");
Route::post('set/store', "EshelfController@store");
Route::get('set/itemdelete/{id}', "EshelfController@itemdelete");
Route::get('set/delete/{id}', "EshelfController@delete");

Route::get('export/{id}', 'QueryController@download');
Route::get('ddlists', "SearchController@ddlists");
