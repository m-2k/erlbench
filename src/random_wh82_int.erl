%-*-Mode:erlang;coding:utf-8;tab-width:4;c-basic-offset:4;indent-tabs-mode:()-*-
% ex: set ft=erlang fenc=utf-8 sts=4 ts=4 sw=4 et nomod:

%% Modified version of random module
%% (to use Erlang's native bigint support instead of floating-point)

%% Copyright (c) 2016 Michael Truog All rights reserved.

%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 1996-2011. All Rights Reserved.
%% 
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%% 
%% %CopyrightEnd%
%%
-module(random_wh82_int).

%% Reasonable random number generator (period is 2.78e13):
%%  The method is attributed to B. A. Wichmann and I. D. Hill
%%  See "An efficient and portable pseudo-random number generator",
%%  Journal of Applied Statistics. AS183. 1982. Also Byte March 1987.

-export([seed0/0, seed/0, seed/1, seed/3,
         uniform/0, uniform/1,
         uniform_s/1, uniform_s/2,
         next_sequence/1]).

% same results as the legacy Erlang/OTP random module (by using floating-point)
-export([uniform_old/0, uniform_old/1,
         uniform_s_old/1, uniform_s_old/2]).

-define(PRIME1, 30269).
-define(PRIME2, 30307).
-define(PRIME3, 30323).

-define(SEED_DICT, random_seed).

%%-----------------------------------------------------------------------
%% The type of the state

-type seed() :: {integer(), integer(), integer()}.

%%-----------------------------------------------------------------------

-spec seed0() -> seed().

seed0() ->
    {3172, 9814, 20125}.

%% seed()
%%  Seed random number generation with default values

-spec seed() -> seed().

seed() ->
    reseed(seed0()).

%% seed({A1, A2, A3}) 
%%  Seed random number generation 

-spec seed({pos_integer(), pos_integer(), pos_integer()}) ->
    'undefined' | seed().

seed({A1, A2, A3}) ->
    seed(A1, A2, A3).

%% seed(A1, A2, A3) 
%%  Seed random number generation 

-spec seed(pos_integer(), pos_integer(), pos_integer()) ->
    'undefined' | seed().

seed(A1, A2, A3)
    when is_integer(A1), A1 > 0,
         is_integer(A2), A2 > 0,
         is_integer(A3), A3 > 0 ->
    put(?SEED_DICT,
        {A1 rem ?PRIME1,
         A2 rem ?PRIME2,
         A3 rem ?PRIME3}).

-spec reseed(seed()) ->
    seed().

reseed({A1, A2, A3}) ->
    case seed(A1, A2, A3) of
        undefined -> seed0();
        {_,_,_} = Tuple -> Tuple
    end.

%% uniform()
%%  Returns a random integer between 0 and 27817185604308.

-spec uniform() -> non_neg_integer().

uniform() ->
    {A1, A2, A3} = case get(?SEED_DICT) of
                       undefined -> seed0();
                       Tuple -> Tuple
                   end,

    B1 = (171 * A1) rem ?PRIME1,
    B2 = (172 * A2) rem ?PRIME2,
    B3 = (170 * A3) rem ?PRIME3,

    put(?SEED_DICT, {B1, B2, B3}),

    I = ((B1 * 918999161) +
         (B2 * 917846887) +
         (B3 * 917362583))
        rem 27817185604309,
    I.

-spec uniform_old() -> float().

uniform_old() ->
    I = uniform(),
    I / 27817185604309.

%% uniform(N) -> I
%%  Given an integer N > 1, N =< 27817185604309,
%%  uniform(N) returns a random integer
%%  between 1 and N.

-spec uniform(pos_integer()) -> pos_integer().

uniform(N)
    when is_integer(N), N > 1, N =< 27817185604309 ->
    (uniform() rem N) + 1.

-spec uniform_old(pos_integer()) -> pos_integer().

uniform_old(N)
    when is_integer(N), N > 1, N =< 27817185604309 ->
    trunc(uniform_old() * N) + 1.

%%% Functional versions

%% uniform_s(State) -> {I, NewState}
%%  Returns a random integer I, between
%%  0 and 27817185604308 (inclusive).

-spec uniform_s(seed()) -> {non_neg_integer(), seed()}.

uniform_s({A1, A2, A3})
    when is_integer(A1), A1 > 0,
         is_integer(A2), A2 > 0,
         is_integer(A3), A3 > 0 ->
    B1 = (171 * A1) rem ?PRIME1,
    B2 = (172 * A2) rem ?PRIME2,
    B3 = (170 * A3) rem ?PRIME3,

    I = ((B1 * 918999161) +
         (B2 * 917846887) +
         (B3 * 917362583))
        rem 27817185604309,

    {I, {B1, B2, B3}}.

-spec uniform_s_old(seed()) -> {float(), seed()}.

uniform_s_old(State0) ->
    {I, State1} = uniform_s(State0),
    {I / 27817185604309, State1}.

%% uniform_s(N, State) -> {I, NewState}
%%  Given an integer N > 1, N =< 27817185604309,
%%  uniform(N) returns a random integer
%%  between 1 and N.

-spec uniform_s(pos_integer(), seed()) -> {pos_integer(), seed()}.

uniform_s(N, State0)
    when is_integer(N), N > 1, N =< 27817185604309 ->
    {I, State1} = uniform_s(State0),
    {(I rem N) + 1, State1}.

-spec uniform_s_old(pos_integer(), seed()) -> {pos_integer(), seed()}.

uniform_s_old(N, State0)
    when is_integer(N), N > 1, N =< 27817185604309 ->
    {F, State1} = uniform_s_old(State0),
    {trunc(F * N) + 1, State1}.

%% generating another seed for multiple sequences

-spec next_sequence(seed()) -> seed().

next_sequence({A1, A2, A3})
    when is_integer(A1), A1 > 0,
         is_integer(A2), A2 > 0,
         is_integer(A3), A3 > 0 ->
    B1 = (171 * A1) rem ?PRIME1,
    B2 = (172 * A2) rem ?PRIME2,
    B3 = (170 * A3) rem ?PRIME3,
    {B1, B2, B3}.

