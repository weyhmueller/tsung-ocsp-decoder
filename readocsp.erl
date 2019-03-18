%%%---------------------------------------------------------------------
%%% Copyright T-Systems International GmbH 2013
%%%
%%% All rights reserved. No part of this computer programs(s) may be
%%% used, reproduced,stored in any retrieval system, or transmitted,
%%% in any form or by any means, electronic, mechanical, photocopying,
%%% recording, or otherwise without prior written permission of
%%% T-Systems International GmbH.
%%%---------------------------------------------------------------------
%%% Revision History
%%%---------------------------------------------------------------------
%%% Rev  1 20130822 Oliver Weyhmueller, oliver.weyhmueller@t-systems.com
%%% Initial release. Functions to decode a OCSP Response from a file
%%% and from binary data.
%%%---------------------------------------------------------------------
%%% Rev  2 20130822 Oliver Weyhmueller, oliver.weyhmueller@t-systems.com
%%% Updated functions to return whole contents of OCSP SingleResponse
%%% instead of certStatus only.
%%%---------------------------------------------------------------------
%%% Rev  3 20130826 Oliver Weyhmueller, oliver.weyhmueller@t-systems.com
%%% Updated functions to return OCSP ResponseStatus if not successful
%%%---------------------------------------------------------------------
-module(readocsp).
-include("OCSP.hrl").
-export([read_from_file/1,read/1]).

read_from_file(File) ->
  {ok, Data} = file:read_file(File),
  read(Data).

read(Data) ->
  OCSPResponse = decoderesponse(Data),
  case OCSPResponse#'OCSPResponse'.responseStatus of
    successful -> BasicOCSPResponse = getbasicresponse(OCSPResponse),
                  SingleResponse = getfirstresponse(BasicOCSPResponse),
                  getstatus(SingleResponse) ++ ";" ++ getissuernamehash(SingleResponse) ++ ";" ++ getissuerkeyhash(SingleResponse) ++ ";" ++ getserialnumber(SingleResponse);
    Other      -> atom_to_list(OCSPResponse#'OCSPResponse'.responseStatus)
  end.

decoderesponse(Data) ->
  {ok,OCSPResponse} = 'OCSP':decode('OCSPResponse',Data),
  OCSPResponse.

getbasicresponse(OCSPResponse) ->
  BasicResponseData = list_to_binary(OCSPResponse#'OCSPResponse'.responseBytes#'ResponseBytes'.response),
  {ok,BasicOCSPResponse} = 'OCSP':decode('BasicOCSPResponse',BasicResponseData),
  BasicOCSPResponse.

getfirstresponse(BasicOCSPResponse) ->
  SingleResponse = hd(BasicOCSPResponse#'BasicOCSPResponse'.tbsResponseData#'ResponseData'.responses),
  SingleResponse.

getstatus(SingleResponse) ->
  {Status,_} = SingleResponse#'SingleResponse'.certStatus,
  atom_to_list(Status).

getissuernamehash(SingleResponse) ->
  IssuerNameHash = SingleResponse#'SingleResponse'.certID#'CertID'.issuerNameHash,
  lists:flatten(list_to_hex(IssuerNameHash)).

getissuerkeyhash(SingleResponse) ->
  IssuerKeyHash = SingleResponse#'SingleResponse'.certID#'CertID'.issuerKeyHash,
  lists:flatten(list_to_hex(IssuerKeyHash)).

getserialnumber(SingleResponse) ->
  Serialnumber = SingleResponse#'SingleResponse'.certID#'CertID'.serialNumber,
  integer_to_list(Serialnumber).

list_to_hex(L) ->
       lists:map(fun(X) -> int_to_hex(X) end, L).

int_to_hex(N) when N < 256 ->
       [hex(N div 16), hex(N rem 16)].

hex(N) when N < 10 ->
       $0+N;
hex(N) when N >= 10, N < 16 ->
       $a + (N-10).
