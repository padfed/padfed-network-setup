#!/bin/bash
[[ -n $DEBUG ]] && set -x
set -Eeuo pipefail

readonly BASE=$(dirname $(readlink -f $0))
. "$BASE/lib.sh"

echo_running

function mocks() {

readonly CONFIG_JSON='
{
  "data": {
    "data": [
      {
        "payload": {
          "data": {
            "config": {
              "channel_group": {
                "groups": {
                  "Consortiums": {
										"groups": {
											"TaxConsortium": {
												"groups": {
													"AFIP": {
														"groups": {},
														"mod_policy": "Admins",
														"policies": {
															"Admins": {
																"mod_policy": "Admins",
																"policy": {
																	"type": 1,
																	"value": {
																		"identities": [
																			{
																				"principal": {
																					"msp_identifier": "AFIP",
																					"role": "ADMIN"
																				},
																				"principal_classification": "ROLE"
																			}
																		],
																		"rule": {
																			"n_out_of": {
																				"n": 1,
																				"rules": [
																					{
																						"signed_by": 0
																					}
																				]
																			}
																		},
																		"version": 0
																	}
																},
																"version": "0"
															},
															"Readers": {
																"mod_policy": "Admins",
																"policy": {
																	"type": 3,
																	"value": {
																		"rule": "ANY",
																		"sub_policy": "Readers"
																	}
																},
																"version": "0"
															},
															"Writers": {
																"mod_policy": "Admins",
																"policy": {
																	"type": 1,
																	"value": {
																		"identities": [
																			{
																				"principal": {
																					"msp_identifier": "XXX",
																					"role": "MEMBER"
																				},
																				"principal_classification": "ROLE"
																			}
																		],
																		"rule": {
																			"n_out_of": {
																				"n": 1,
																				"rules": [
																					{
																						"signed_by": 0
																					}
																				]
																			}
																		},
																		"version": 0
																	}
																},
																"version": "0"
															}
														},
														"values": {
															"MSP": {
																"mod_policy": "Admins",
                                "value": {
                                  "config": {
                                    "admins": [],
                                    "crypto_config": {
                                      "identity_identifier_hash_function": "SHA256",
                                      "signature_hash_family": "SHA2"
                                    },
                                    "fabric_node_ous": {
                                      "admin_ou_identifier": {
                                        "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                        "organizational_unit_identifier": "admin"
                                      },
                                      "client_ou_identifier": {
                                        "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                        "organizational_unit_identifier": "client"
                                      },
                                      "enable": true,
                                      "orderer_ou_identifier": {
                                        "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                        "organizational_unit_identifier": "orderer"
                                      },
                                      "peer_ou_identifier": {
                                        "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                        "organizational_unit_identifier": "peer"
                                      }
                                    },
                                    "intermediate_certs": [],
                                    "name": "AFIP",
															   		"organizational_unit_identifiers": [ 
                                      {
															   				"certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
															   				"organizational_unit_identifier": "MSP-TRIBUTARIA"
															   			}
															   		],
                                    "revocation_list": [],
                                    "root_certs": [
                                      "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
                                    ],
                                    "signing_identity": null,
                                    "tls_intermediate_certs": [],
                                    "tls_root_certs": [
                                      "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNhRENDQWc2Z0F3SUJBZ0lSQUxZeVBKeU9GcTkxR01vb2FFQmdjVUl3Q2dZSUtvWkl6ajBFQXdJd2ZqRUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFaU1DQUdBMVVFCkF4TVpkR3h6WTJFdVlXWnBjQzUwY21saVptVmtMbWR2WWk1aGNqQWVGdzB4T1RFd01EUXhOakl5TURCYUZ3MHkKT1RFd01ERXhOakl5TURCYU1INHhDekFKQmdOVkJBWVRBa0ZTTVEwd0N3WURWUVFJRXdSRFFVSkJNUTB3Q3dZRApWUVFIRXdSRFFVSkJNUnd3R2dZRFZRUUtFeE5oWm1sd0xuUnlhV0ptWldRdVoyOWlMbUZ5TVE4d0RRWURWUVFMCkV3WlRSRWRUU1ZReElqQWdCZ05WQkFNVEdYUnNjMk5oTG1GbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJd1dUQVQKQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FBU0R5OUhUUHIrSzM2N1hEazd3dm4yRHlZYVZsZlY2Y2V4Vwp3MlNJRk9PdE13Zlg0aGJ5bDNqYnBLK0IyMy8xMUFoQ3BVMit0M3pNRXlhdFNCTDJVVEV4bzIwd2F6QU9CZ05WCkhROEJBZjhFQkFNQ0FhWXdIUVlEVlIwbEJCWXdGQVlJS3dZQkJRVUhBd0lHQ0NzR0FRVUZCd01CTUE4R0ExVWQKRXdFQi93UUZNQU1CQWY4d0tRWURWUjBPQkNJRUlEL0R4MGxEVExBZ2haNVFsQUQrOXgwaW4rUStST1QyclhxegpWd1ZqeTNYSk1Bb0dDQ3FHU000OUJBTUNBMGdBTUVVQ0lRQzJzR2M5MnpqM2Ntd082bFRpRWViYjAyQ0thRnhJCkx0ZnRsQm5nWW5OY1NRSWdSQ1EwYUdjeGFoaUlmNnlNRHoxV1VDSkZBVHU2d2Y1eFErMGR1TXFReFg4PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                                    ]
                                  },
                                  "type": 0
                                },
																"version": "0"
															}
														},
														"version": "0"
													}
												},
												"mod_policy": "/Channel/Orderer/Admins",
												"policies": {},
												"values": {
													"ChannelCreationPolicy": {
														"mod_policy": "/Channel/Orderer/Admins",
														"value": {
															"type": 3,
															"value": {
																"rule": "ANY",
																"sub_policy": "Admins"
															}
														},
														"version": "0"
													}
												},
												"version": "0"
											}
										},
										"mod_policy": "/Channel/Orderer/Admins",
										"policies": {
											"Admins": {
												"mod_policy": "/Channel/Orderer/Admins",
												"policy": {
													"type": 1,
													"value": {
														"identities": [],
														"rule": {
															"n_out_of": {
																"n": 0,
																"rules": []
															}
														},
														"version": 0
													}
												},
												"version": "0"
											}
										},
										"values": {},
										"version": "0"
									},
                  "Application": {
                    "groups": {
                      "AFIP": {
                        "groups": {},
                        "mod_policy": "Admins",
                        "policies": {
                          "Admins": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Readers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "CLIENT"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "PEER"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      },
                                      {
                                        "signed_by": 1
                                      },
                                      {
                                        "signed_by": 2
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Writers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "MEMBER"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          }
                        },
                        "values": {
                          "AnchorPeers": {
                            "mod_policy": "Admins",
                            "value": {
                              "anchor_peers": [
                                {
                                  "host": "peer0.afip.tribfed.gob.ar",
                                  "port": 7051
                                }
                              ]
                            },
                            "version": "0"
                          },
                          "MSP": {
                            "mod_policy": "Admins",
                            "value": {
                              "config": {
                                "admins": [],
                                "crypto_config": {
                                  "identity_identifier_hash_function": "SHA256",
                                  "signature_hash_family": "SHA2"
                                },
                                "fabric_node_ous": {
                                  "admin_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "admin"
                                  },
                                  "client_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "client"
                                  },
                                  "enable": true,
                                  "orderer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "orderer"
                                  },
                                  "peer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "peer"
                                  }
                                },
                                "intermediate_certs": [],
                                "name": "AFIP",
																"organizational_unit_identifiers": [ 
                                  {
																		"certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
																		"organizational_unit_identifier": "MSP-TRIBUTARIA"
																	}
																],
                                "revocation_list": [],
                                "root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
                                ],
                                "signing_identity": null,
                                "tls_intermediate_certs": [],
                                "tls_root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNhRENDQWc2Z0F3SUJBZ0lSQUxZeVBKeU9GcTkxR01vb2FFQmdjVUl3Q2dZSUtvWkl6ajBFQXdJd2ZqRUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFaU1DQUdBMVVFCkF4TVpkR3h6WTJFdVlXWnBjQzUwY21saVptVmtMbWR2WWk1aGNqQWVGdzB4T1RFd01EUXhOakl5TURCYUZ3MHkKT1RFd01ERXhOakl5TURCYU1INHhDekFKQmdOVkJBWVRBa0ZTTVEwd0N3WURWUVFJRXdSRFFVSkJNUTB3Q3dZRApWUVFIRXdSRFFVSkJNUnd3R2dZRFZRUUtFeE5oWm1sd0xuUnlhV0ptWldRdVoyOWlMbUZ5TVE4d0RRWURWUVFMCkV3WlRSRWRUU1ZReElqQWdCZ05WQkFNVEdYUnNjMk5oTG1GbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJd1dUQVQKQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FBU0R5OUhUUHIrSzM2N1hEazd3dm4yRHlZYVZsZlY2Y2V4Vwp3MlNJRk9PdE13Zlg0aGJ5bDNqYnBLK0IyMy8xMUFoQ3BVMit0M3pNRXlhdFNCTDJVVEV4bzIwd2F6QU9CZ05WCkhROEJBZjhFQkFNQ0FhWXdIUVlEVlIwbEJCWXdGQVlJS3dZQkJRVUhBd0lHQ0NzR0FRVUZCd01CTUE4R0ExVWQKRXdFQi93UUZNQU1CQWY4d0tRWURWUjBPQkNJRUlEL0R4MGxEVExBZ2haNVFsQUQrOXgwaW4rUStST1QyclhxegpWd1ZqeTNYSk1Bb0dDQ3FHU000OUJBTUNBMGdBTUVVQ0lRQzJzR2M5MnpqM2Ntd082bFRpRWViYjAyQ0thRnhJCkx0ZnRsQm5nWW5OY1NRSWdSQ1EwYUdjeGFoaUlmNnlNRHoxV1VDSkZBVHU2d2Y1eFErMGR1TXFReFg4PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                                ]
                              },
                              "type": 0
                            },
                            "version": "0"
                          }
                        },
                        "version": "1"
                      },
                      "ARBA": {
                        "groups": {},
                        "mod_policy": "Admins",
                        "policies": {
                          "Admins": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "ARBA",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Readers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "ARBA",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "ARBA",
                                      "role": "CLIENT"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "ARBA",
                                      "role": "PEER"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      },
                                      {
                                        "signed_by": 1
                                      },
                                      {
                                        "signed_by": 2
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Writers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "ARBA",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "ARBA",
                                      "role": "CLIENT"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "ARBA",
                                      "role": "PEER"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      },
                                      {
                                        "signed_by": 1
                                      },
                                      {
                                        "signed_by": 2
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          }
                        },
                        "values": {
                          "AnchorPeers": {
                            "mod_policy": "Admins",
                            "value": {
                              "anchor_peers": [
                                {
                                  "host": "peer0.arba.tribfed.gob.ar",
                                  "port": 7051
                                }
                              ]
                            },
                            "version": "0"
                          },
                          "MSP": {
                            "mod_policy": "Admins",
                            "value": {
                              "config": {
                                "admins": [],
                                "crypto_config": {
                                  "identity_identifier_hash_function": "SHA256",
                                  "signature_hash_family": "SHA2"
                                },
                                "fabric_node_ous": {
                                  "admin_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNkekNDQWg2Z0F3SUJBZ0lSQU1TZElrSGxTKzEzSElpUHFMYjNZL2t3Q2dZSUtvWkl6ajBFQXdJd2dZVXgKQ3pBSkJnTlZCQVlUQWtGU01SVXdFd1lEVlFRSUV3eENkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aApJRkJzWVhSaE1Sd3dHZ1lEVlFRS0V4TmhjbUpoTG5SeWFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIClIxUkpNUjh3SFFZRFZRUURFeFpqWVM1aGNtSmhMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTIKTWpJd01Gb1hEVEk1TVRBd01URTJNakl3TUZvd2dZVXhDekFKQmdOVkJBWVRBa0ZTTVJVd0V3WURWUVFJRXd4QwpkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aElGQnNZWFJoTVJ3d0dnWURWUVFLRXhOaGNtSmhMblJ5CmFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIUjFSSk1SOHdIUVlEVlFRREV4WmpZUzVoY21KaExuUnkKYVdKbVpXUXVaMjlpTG1GeU1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRXpjUWhPODB2SFdsaApiYnVmOFhzZW5iZ3RqQ1VBQWlCc2diRjMrY3VrbHFuMkNEbThnNkZpS2tnRlM2WFY5MTdOYVlIUTZhY3dBSUE2Ckx2Y08rT25oS2FOdE1Hc3dEZ1lEVlIwUEFRSC9CQVFEQWdHbU1CMEdBMVVkSlFRV01CUUdDQ3NHQVFVRkJ3TUMKQmdnckJnRUZCUWNEQVRBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUNrR0ExVWREZ1FpQkNDV2tkM1JWNUNHd3BVYwpMRG5kaVk2VGNkbVdCNGQ3TUdvR3cwMGlBT2FTT2pBS0JnZ3Foa2pPUFFRREFnTkhBREJFQWlCMXd2NUxNUHFTCldnc3drczBQKzZ2RTBDdFc4ZkhpbVl5QzBNSHVMNytWYUFJZ1ZSTXF3WWJWajhiS3Z0RTZaak52b1dWekVmQXQKLzVta1Arc3ZJSkZkcWdJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==",
                                    "organizational_unit_identifier": "admin"
                                  },
                                  "client_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNkekNDQWg2Z0F3SUJBZ0lSQU1TZElrSGxTKzEzSElpUHFMYjNZL2t3Q2dZSUtvWkl6ajBFQXdJd2dZVXgKQ3pBSkJnTlZCQVlUQWtGU01SVXdFd1lEVlFRSUV3eENkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aApJRkJzWVhSaE1Sd3dHZ1lEVlFRS0V4TmhjbUpoTG5SeWFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIClIxUkpNUjh3SFFZRFZRUURFeFpqWVM1aGNtSmhMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTIKTWpJd01Gb1hEVEk1TVRBd01URTJNakl3TUZvd2dZVXhDekFKQmdOVkJBWVRBa0ZTTVJVd0V3WURWUVFJRXd4QwpkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aElGQnNZWFJoTVJ3d0dnWURWUVFLRXhOaGNtSmhMblJ5CmFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIUjFSSk1SOHdIUVlEVlFRREV4WmpZUzVoY21KaExuUnkKYVdKbVpXUXVaMjlpTG1GeU1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRXpjUWhPODB2SFdsaApiYnVmOFhzZW5iZ3RqQ1VBQWlCc2diRjMrY3VrbHFuMkNEbThnNkZpS2tnRlM2WFY5MTdOYVlIUTZhY3dBSUE2Ckx2Y08rT25oS2FOdE1Hc3dEZ1lEVlIwUEFRSC9CQVFEQWdHbU1CMEdBMVVkSlFRV01CUUdDQ3NHQVFVRkJ3TUMKQmdnckJnRUZCUWNEQVRBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUNrR0ExVWREZ1FpQkNDV2tkM1JWNUNHd3BVYwpMRG5kaVk2VGNkbVdCNGQ3TUdvR3cwMGlBT2FTT2pBS0JnZ3Foa2pPUFFRREFnTkhBREJFQWlCMXd2NUxNUHFTCldnc3drczBQKzZ2RTBDdFc4ZkhpbVl5QzBNSHVMNytWYUFJZ1ZSTXF3WWJWajhiS3Z0RTZaak52b1dWekVmQXQKLzVta1Arc3ZJSkZkcWdJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==",
                                    "organizational_unit_identifier": "client"
                                  },
                                  "enable": true,
                                  "orderer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNkekNDQWg2Z0F3SUJBZ0lSQU1TZElrSGxTKzEzSElpUHFMYjNZL2t3Q2dZSUtvWkl6ajBFQXdJd2dZVXgKQ3pBSkJnTlZCQVlUQWtGU01SVXdFd1lEVlFRSUV3eENkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aApJRkJzWVhSaE1Sd3dHZ1lEVlFRS0V4TmhjbUpoTG5SeWFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIClIxUkpNUjh3SFFZRFZRUURFeFpqWVM1aGNtSmhMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTIKTWpJd01Gb1hEVEk1TVRBd01URTJNakl3TUZvd2dZVXhDekFKQmdOVkJBWVRBa0ZTTVJVd0V3WURWUVFJRXd4QwpkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aElGQnNZWFJoTVJ3d0dnWURWUVFLRXhOaGNtSmhMblJ5CmFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIUjFSSk1SOHdIUVlEVlFRREV4WmpZUzVoY21KaExuUnkKYVdKbVpXUXVaMjlpTG1GeU1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRXpjUWhPODB2SFdsaApiYnVmOFhzZW5iZ3RqQ1VBQWlCc2diRjMrY3VrbHFuMkNEbThnNkZpS2tnRlM2WFY5MTdOYVlIUTZhY3dBSUE2Ckx2Y08rT25oS2FOdE1Hc3dEZ1lEVlIwUEFRSC9CQVFEQWdHbU1CMEdBMVVkSlFRV01CUUdDQ3NHQVFVRkJ3TUMKQmdnckJnRUZCUWNEQVRBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUNrR0ExVWREZ1FpQkNDV2tkM1JWNUNHd3BVYwpMRG5kaVk2VGNkbVdCNGQ3TUdvR3cwMGlBT2FTT2pBS0JnZ3Foa2pPUFFRREFnTkhBREJFQWlCMXd2NUxNUHFTCldnc3drczBQKzZ2RTBDdFc4ZkhpbVl5QzBNSHVMNytWYUFJZ1ZSTXF3WWJWajhiS3Z0RTZaak52b1dWekVmQXQKLzVta1Arc3ZJSkZkcWdJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==",
                                    "organizational_unit_identifier": "orderer"
                                  },
                                  "peer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNkekNDQWg2Z0F3SUJBZ0lSQU1TZElrSGxTKzEzSElpUHFMYjNZL2t3Q2dZSUtvWkl6ajBFQXdJd2dZVXgKQ3pBSkJnTlZCQVlUQWtGU01SVXdFd1lEVlFRSUV3eENkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aApJRkJzWVhSaE1Sd3dHZ1lEVlFRS0V4TmhjbUpoTG5SeWFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIClIxUkpNUjh3SFFZRFZRUURFeFpqWVM1aGNtSmhMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTIKTWpJd01Gb1hEVEk1TVRBd01URTJNakl3TUZvd2dZVXhDekFKQmdOVkJBWVRBa0ZTTVJVd0V3WURWUVFJRXd4QwpkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aElGQnNZWFJoTVJ3d0dnWURWUVFLRXhOaGNtSmhMblJ5CmFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIUjFSSk1SOHdIUVlEVlFRREV4WmpZUzVoY21KaExuUnkKYVdKbVpXUXVaMjlpTG1GeU1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRXpjUWhPODB2SFdsaApiYnVmOFhzZW5iZ3RqQ1VBQWlCc2diRjMrY3VrbHFuMkNEbThnNkZpS2tnRlM2WFY5MTdOYVlIUTZhY3dBSUE2Ckx2Y08rT25oS2FOdE1Hc3dEZ1lEVlIwUEFRSC9CQVFEQWdHbU1CMEdBMVVkSlFRV01CUUdDQ3NHQVFVRkJ3TUMKQmdnckJnRUZCUWNEQVRBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUNrR0ExVWREZ1FpQkNDV2tkM1JWNUNHd3BVYwpMRG5kaVk2VGNkbVdCNGQ3TUdvR3cwMGlBT2FTT2pBS0JnZ3Foa2pPUFFRREFnTkhBREJFQWlCMXd2NUxNUHFTCldnc3drczBQKzZ2RTBDdFc4ZkhpbVl5QzBNSHVMNytWYUFJZ1ZSTXF3WWJWajhiS3Z0RTZaak52b1dWekVmQXQKLzVta1Arc3ZJSkZkcWdJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==",
                                    "organizational_unit_identifier": "peer"
                                  }
                                },
                                "intermediate_certs": [],
                                "name": "ARBA",
                                "organizational_unit_identifiers": [],
                                "revocation_list": [],
                                "root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNkekNDQWg2Z0F3SUJBZ0lSQU1TZElrSGxTKzEzSElpUHFMYjNZL2t3Q2dZSUtvWkl6ajBFQXdJd2dZVXgKQ3pBSkJnTlZCQVlUQWtGU01SVXdFd1lEVlFRSUV3eENkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aApJRkJzWVhSaE1Sd3dHZ1lEVlFRS0V4TmhjbUpoTG5SeWFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIClIxUkpNUjh3SFFZRFZRUURFeFpqWVM1aGNtSmhMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTIKTWpJd01Gb1hEVEk1TVRBd01URTJNakl3TUZvd2dZVXhDekFKQmdOVkJBWVRBa0ZTTVJVd0V3WURWUVFJRXd4QwpkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aElGQnNZWFJoTVJ3d0dnWURWUVFLRXhOaGNtSmhMblJ5CmFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIUjFSSk1SOHdIUVlEVlFRREV4WmpZUzVoY21KaExuUnkKYVdKbVpXUXVaMjlpTG1GeU1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRXpjUWhPODB2SFdsaApiYnVmOFhzZW5iZ3RqQ1VBQWlCc2diRjMrY3VrbHFuMkNEbThnNkZpS2tnRlM2WFY5MTdOYVlIUTZhY3dBSUE2Ckx2Y08rT25oS2FOdE1Hc3dEZ1lEVlIwUEFRSC9CQVFEQWdHbU1CMEdBMVVkSlFRV01CUUdDQ3NHQVFVRkJ3TUMKQmdnckJnRUZCUWNEQVRBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUNrR0ExVWREZ1FpQkNDV2tkM1JWNUNHd3BVYwpMRG5kaVk2VGNkbVdCNGQ3TUdvR3cwMGlBT2FTT2pBS0JnZ3Foa2pPUFFRREFnTkhBREJFQWlCMXd2NUxNUHFTCldnc3drczBQKzZ2RTBDdFc4ZkhpbVl5QzBNSHVMNytWYUFJZ1ZSTXF3WWJWajhiS3Z0RTZaak52b1dWekVmQXQKLzVta1Arc3ZJSkZkcWdJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                                ],
                                "signing_identity": null,
                                "tls_intermediate_certs": [],
                                "tls_root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNmakNDQWlTZ0F3SUJBZ0lSQU53Q3diUGFFeUtDUnFNSEFPWnlockF3Q2dZSUtvWkl6ajBFQXdJd2dZZ3gKQ3pBSkJnTlZCQVlUQWtGU01SVXdFd1lEVlFRSUV3eENkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aApJRkJzWVhSaE1Sd3dHZ1lEVlFRS0V4TmhjbUpoTG5SeWFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIClIxUkpNU0l3SUFZRFZRUURFeGwwYkhOallTNWhjbUpoTG5SeWFXSm1aV1F1WjI5aUxtRnlNQjRYRFRFNU1UQXcKTkRFMk1qSXdNRm9YRFRJNU1UQXdNVEUyTWpJd01Gb3dnWWd4Q3pBSkJnTlZCQVlUQWtGU01SVXdFd1lEVlFRSQpFd3hDZFdWdWIzTWdRV2x5WlhNeEVUQVBCZ05WQkFjVENFeGhJRkJzWVhSaE1Sd3dHZ1lEVlFRS0V4TmhjbUpoCkxuUnlhV0ptWldRdVoyOWlMbUZ5TVEwd0N3WURWUVFMRXdSSFIxUkpNU0l3SUFZRFZRUURFeGwwYkhOallTNWgKY21KaExuUnlhV0ptWldRdVoyOWlMbUZ5TUZrd0V3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFL0MxTgpqdTZpbXVaUkxFSTIyS05pcWNRcmZOOFhyNXNMR050Z3RiNmQ4VWo1OXR6U2dhMWZtQjRLb01wbVgwaXR6cWpvCnJUMmd3UDFNZGJxNEpIWkxzcU50TUdzd0RnWURWUjBQQVFIL0JBUURBZ0dtTUIwR0ExVWRKUVFXTUJRR0NDc0cKQVFVRkJ3TUNCZ2dyQmdFRkJRY0RBVEFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQ2tHQTFVZERnUWlCQ0FxT0Zpbwpza0RjakU1a3BoSHVxNk1xZXpiK3FTY3ZPRk8xWDllbjd1bDFMREFLQmdncWhrak9QUVFEQWdOSUFEQkZBaUVBCm05QzdndGlNa1Y0RFdkYzNpelBETnNMRTY2eFNZK2Y2N2lRdmZGVHpzZ1VDSUFaOVhZTXVRdXhqeGFTT0hCaW8KUURvRW92UzVWOFdnVFFwT3d2azByV3lXCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
                                ]
                              },
                              "type": 0
                            },
                            "version": "0"
                          }
                        },
                        "version": "1"
                      },
                      "COMARB": {
                        "groups": {},
                        "mod_policy": "Admins",
                        "policies": {
                          "Admins": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "COMARB",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Readers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "COMARB",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "COMARB",
                                      "role": "CLIENT"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "COMARB",
                                      "role": "PEER"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      },
                                      {
                                        "signed_by": 1
                                      },
                                      {
                                        "signed_by": 2
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Writers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "COMARB",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "COMARB",
                                      "role": "CLIENT"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "COMARB",
                                      "role": "PEER"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      },
                                      {
                                        "signed_by": 1
                                      },
                                      {
                                        "signed_by": 2
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          }
                        },
                        "values": {
                          "AnchorPeers": {
                            "mod_policy": "Admins",
                            "value": {
                              "anchor_peers": [
                                {
                                  "host": "peer0.comarb.tribfed.gob.ar",
                                  "port": 7051
                                }
                              ]
                            },
                            "version": "0"
                          },
                          "MSP": {
                            "mod_policy": "Admins",
                            "value": {
                              "config": {
                                "admins": [],
                                "crypto_config": {
                                  "identity_identifier_hash_function": "SHA256",
                                  "signature_hash_family": "SHA2"
                                },
                                "fabric_node_ous": {
                                  "admin_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZekNDQWdtZ0F3SUJBZ0lRR0RoUTlTNk1qVERMUS9CU2lhMUlYakFLQmdncWhrak9QUVFEQWpCOE1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWVNQndHQTFVRQpDaE1WWTI5dFlYSmlMblJ5YVdKbVpXUXVaMjlpTG1GeU1Rd3dDZ1lEVlFRTEV3TkhWRWt4SVRBZkJnTlZCQU1UCkdHTmhMbU52YldGeVlpNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUh3eEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1SNHdIQVlEVlFRS0V4VmpiMjFoY21JdWRISnBZbVpsWkM1bmIySXVZWEl4RERBS0JnTlZCQXNUCkEwZFVTVEVoTUI4R0ExVUVBeE1ZWTJFdVkyOXRZWEppTG5SeWFXSm1aV1F1WjI5aUxtRnlNRmt3RXdZSEtvWkkKemowQ0FRWUlLb1pJemowREFRY0RRZ0FFOG5ydHVINjc5elNmZUU5UlAwOFdQOC9RSzZZcjZOS2tKTnJWc2dKbwpKaTdNV3kyNkVKNTVpYk56cERQWjhqMlJ3dHRFcWhzUVFEY0RmUVZBY3ptQ01xTnRNR3N3RGdZRFZSMFBBUUgvCkJBUURBZ0dtTUIwR0ExVWRKUVFXTUJRR0NDc0dBUVVGQndNQ0JnZ3JCZ0VGQlFjREFUQVBCZ05WSFJNQkFmOEUKQlRBREFRSC9NQ2tHQTFVZERnUWlCQ0RZOHpkOFhFR3B2U3dBSFVManlqdG4yNGdFbUVHTFNtNDgvamFXVEJzdwplVEFLQmdncWhrak9QUVFEQWdOSUFEQkZBaUVBaE8xTW91NUd4ZlV5cU9SaXRKbGpOSzFyRHFoNmNLc21xbFV0ClY2ZkVSSElDSUJ1VFlXVnVDblBRdmVlajIvUHJNMjZSdlhrMDRTdStiVkgySEZlZGphcmsKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "admin"
                                  },
                                  "client_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZekNDQWdtZ0F3SUJBZ0lRR0RoUTlTNk1qVERMUS9CU2lhMUlYakFLQmdncWhrak9QUVFEQWpCOE1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWVNQndHQTFVRQpDaE1WWTI5dFlYSmlMblJ5YVdKbVpXUXVaMjlpTG1GeU1Rd3dDZ1lEVlFRTEV3TkhWRWt4SVRBZkJnTlZCQU1UCkdHTmhMbU52YldGeVlpNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUh3eEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1SNHdIQVlEVlFRS0V4VmpiMjFoY21JdWRISnBZbVpsWkM1bmIySXVZWEl4RERBS0JnTlZCQXNUCkEwZFVTVEVoTUI4R0ExVUVBeE1ZWTJFdVkyOXRZWEppTG5SeWFXSm1aV1F1WjI5aUxtRnlNRmt3RXdZSEtvWkkKemowQ0FRWUlLb1pJemowREFRY0RRZ0FFOG5ydHVINjc5elNmZUU5UlAwOFdQOC9RSzZZcjZOS2tKTnJWc2dKbwpKaTdNV3kyNkVKNTVpYk56cERQWjhqMlJ3dHRFcWhzUVFEY0RmUVZBY3ptQ01xTnRNR3N3RGdZRFZSMFBBUUgvCkJBUURBZ0dtTUIwR0ExVWRKUVFXTUJRR0NDc0dBUVVGQndNQ0JnZ3JCZ0VGQlFjREFUQVBCZ05WSFJNQkFmOEUKQlRBREFRSC9NQ2tHQTFVZERnUWlCQ0RZOHpkOFhFR3B2U3dBSFVManlqdG4yNGdFbUVHTFNtNDgvamFXVEJzdwplVEFLQmdncWhrak9QUVFEQWdOSUFEQkZBaUVBaE8xTW91NUd4ZlV5cU9SaXRKbGpOSzFyRHFoNmNLc21xbFV0ClY2ZkVSSElDSUJ1VFlXVnVDblBRdmVlajIvUHJNMjZSdlhrMDRTdStiVkgySEZlZGphcmsKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "client"
                                  },
                                  "enable": true,
                                  "orderer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZekNDQWdtZ0F3SUJBZ0lRR0RoUTlTNk1qVERMUS9CU2lhMUlYakFLQmdncWhrak9QUVFEQWpCOE1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWVNQndHQTFVRQpDaE1WWTI5dFlYSmlMblJ5YVdKbVpXUXVaMjlpTG1GeU1Rd3dDZ1lEVlFRTEV3TkhWRWt4SVRBZkJnTlZCQU1UCkdHTmhMbU52YldGeVlpNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUh3eEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1SNHdIQVlEVlFRS0V4VmpiMjFoY21JdWRISnBZbVpsWkM1bmIySXVZWEl4RERBS0JnTlZCQXNUCkEwZFVTVEVoTUI4R0ExVUVBeE1ZWTJFdVkyOXRZWEppTG5SeWFXSm1aV1F1WjI5aUxtRnlNRmt3RXdZSEtvWkkKemowQ0FRWUlLb1pJemowREFRY0RRZ0FFOG5ydHVINjc5elNmZUU5UlAwOFdQOC9RSzZZcjZOS2tKTnJWc2dKbwpKaTdNV3kyNkVKNTVpYk56cERQWjhqMlJ3dHRFcWhzUVFEY0RmUVZBY3ptQ01xTnRNR3N3RGdZRFZSMFBBUUgvCkJBUURBZ0dtTUIwR0ExVWRKUVFXTUJRR0NDc0dBUVVGQndNQ0JnZ3JCZ0VGQlFjREFUQVBCZ05WSFJNQkFmOEUKQlRBREFRSC9NQ2tHQTFVZERnUWlCQ0RZOHpkOFhFR3B2U3dBSFVManlqdG4yNGdFbUVHTFNtNDgvamFXVEJzdwplVEFLQmdncWhrak9QUVFEQWdOSUFEQkZBaUVBaE8xTW91NUd4ZlV5cU9SaXRKbGpOSzFyRHFoNmNLc21xbFV0ClY2ZkVSSElDSUJ1VFlXVnVDblBRdmVlajIvUHJNMjZSdlhrMDRTdStiVkgySEZlZGphcmsKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "orderer"
                                  },
                                  "peer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZekNDQWdtZ0F3SUJBZ0lRR0RoUTlTNk1qVERMUS9CU2lhMUlYakFLQmdncWhrak9QUVFEQWpCOE1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWVNQndHQTFVRQpDaE1WWTI5dFlYSmlMblJ5YVdKbVpXUXVaMjlpTG1GeU1Rd3dDZ1lEVlFRTEV3TkhWRWt4SVRBZkJnTlZCQU1UCkdHTmhMbU52YldGeVlpNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUh3eEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1SNHdIQVlEVlFRS0V4VmpiMjFoY21JdWRISnBZbVpsWkM1bmIySXVZWEl4RERBS0JnTlZCQXNUCkEwZFVTVEVoTUI4R0ExVUVBeE1ZWTJFdVkyOXRZWEppTG5SeWFXSm1aV1F1WjI5aUxtRnlNRmt3RXdZSEtvWkkKemowQ0FRWUlLb1pJemowREFRY0RRZ0FFOG5ydHVINjc5elNmZUU5UlAwOFdQOC9RSzZZcjZOS2tKTnJWc2dKbwpKaTdNV3kyNkVKNTVpYk56cERQWjhqMlJ3dHRFcWhzUVFEY0RmUVZBY3ptQ01xTnRNR3N3RGdZRFZSMFBBUUgvCkJBUURBZ0dtTUIwR0ExVWRKUVFXTUJRR0NDc0dBUVVGQndNQ0JnZ3JCZ0VGQlFjREFUQVBCZ05WSFJNQkFmOEUKQlRBREFRSC9NQ2tHQTFVZERnUWlCQ0RZOHpkOFhFR3B2U3dBSFVManlqdG4yNGdFbUVHTFNtNDgvamFXVEJzdwplVEFLQmdncWhrak9QUVFEQWdOSUFEQkZBaUVBaE8xTW91NUd4ZlV5cU9SaXRKbGpOSzFyRHFoNmNLc21xbFV0ClY2ZkVSSElDSUJ1VFlXVnVDblBRdmVlajIvUHJNMjZSdlhrMDRTdStiVkgySEZlZGphcmsKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "peer"
                                  }
                                },
                                "intermediate_certs": [],
                                "name": "COMARB",
                                "organizational_unit_identifiers": [],
                                "revocation_list": [],
                                "root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZekNDQWdtZ0F3SUJBZ0lRR0RoUTlTNk1qVERMUS9CU2lhMUlYakFLQmdncWhrak9QUVFEQWpCOE1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWVNQndHQTFVRQpDaE1WWTI5dFlYSmlMblJ5YVdKbVpXUXVaMjlpTG1GeU1Rd3dDZ1lEVlFRTEV3TkhWRWt4SVRBZkJnTlZCQU1UCkdHTmhMbU52YldGeVlpNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUh3eEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1SNHdIQVlEVlFRS0V4VmpiMjFoY21JdWRISnBZbVpsWkM1bmIySXVZWEl4RERBS0JnTlZCQXNUCkEwZFVTVEVoTUI4R0ExVUVBeE1ZWTJFdVkyOXRZWEppTG5SeWFXSm1aV1F1WjI5aUxtRnlNRmt3RXdZSEtvWkkKemowQ0FRWUlLb1pJemowREFRY0RRZ0FFOG5ydHVINjc5elNmZUU5UlAwOFdQOC9RSzZZcjZOS2tKTnJWc2dKbwpKaTdNV3kyNkVKNTVpYk56cERQWjhqMlJ3dHRFcWhzUVFEY0RmUVZBY3ptQ01xTnRNR3N3RGdZRFZSMFBBUUgvCkJBUURBZ0dtTUIwR0ExVWRKUVFXTUJRR0NDc0dBUVVGQndNQ0JnZ3JCZ0VGQlFjREFUQVBCZ05WSFJNQkFmOEUKQlRBREFRSC9NQ2tHQTFVZERnUWlCQ0RZOHpkOFhFR3B2U3dBSFVManlqdG4yNGdFbUVHTFNtNDgvamFXVEJzdwplVEFLQmdncWhrak9QUVFEQWdOSUFEQkZBaUVBaE8xTW91NUd4ZlV5cU9SaXRKbGpOSzFyRHFoNmNLc21xbFV0ClY2ZkVSSElDSUJ1VFlXVnVDblBRdmVlajIvUHJNMjZSdlhrMDRTdStiVkgySEZlZGphcmsKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
                                ],
                                "signing_identity": null,
                                "tls_intermediate_certs": [],
                                "tls_root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNhRENDQWcrZ0F3SUJBZ0lRYkxqSUo5ZzkyNVpxejVXUlpGejBvakFLQmdncWhrak9QUVFEQWpCL01Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWVNQndHQTFVRQpDaE1WWTI5dFlYSmlMblJ5YVdKbVpXUXVaMjlpTG1GeU1Rd3dDZ1lEVlFRTEV3TkhWRWt4SkRBaUJnTlZCQU1UCkczUnNjMk5oTG1OdmJXRnlZaTUwY21saVptVmtMbWR2WWk1aGNqQWVGdzB4T1RFd01EUXhOakl5TURCYUZ3MHkKT1RFd01ERXhOakl5TURCYU1IOHhDekFKQmdOVkJBWVRBa0ZTTVEwd0N3WURWUVFJRXdSRFFVSkJNUTB3Q3dZRApWUVFIRXdSRFFVSkJNUjR3SEFZRFZRUUtFeFZqYjIxaGNtSXVkSEpwWW1abFpDNW5iMkl1WVhJeEREQUtCZ05WCkJBc1RBMGRVU1RFa01DSUdBMVVFQXhNYmRHeHpZMkV1WTI5dFlYSmlMblJ5YVdKbVpXUXVaMjlpTG1GeU1Ga3cKRXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUVZMFR5dzZiVmpDN0ZrcXZBeWJEaW1VTlVpU1MyZ3FrUAppN2g1dEtxazVqYVQrQjhpOEZ5UHhsWFRPZm8wMGllejVYOGhXbEoxT0tHZmo0MW9EYy9IbmFOdE1Hc3dEZ1lEClZSMFBBUUgvQkFRREFnR21NQjBHQTFVZEpRUVdNQlFHQ0NzR0FRVUZCd01DQmdnckJnRUZCUWNEQVRBUEJnTlYKSFJNQkFmOEVCVEFEQVFIL01Da0dBMVVkRGdRaUJDQ3JLN3luWXBCQ3FaNXlKRGQvTkNnYiszTmUrZ0ZkNXIzKwpCd3VycGJ4blhUQUtCZ2dxaGtqT1BRUURBZ05IQURCRUFpQk1KNTRVOVpsKzRCRU41ZGtjVk9sZG1kSjRBby9aCjhQS2Jrb3M2dk80Qy93SWdBUWlDYmxLOUZ0ZjM2ai96VTMxNDU4alU0eGQyUENITjY5RXpLdG1ON1dJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                                ]
                              },
                              "type": 0
                            },
                            "version": "0"
                          }
                        },
                        "version": "1"
                      },
                      "MORGS": {
                        "groups": {},
                        "mod_policy": "Admins",
                        "policies": {
                          "Admins": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "MORGS",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Readers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "MORGS",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "MORGS",
                                      "role": "CLIENT"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      },
                                      {
                                        "signed_by": 1
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Writers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "MORGS",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "MORGS",
                                      "role": "CLIENT"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      },
                                      {
                                        "signed_by": 1
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          }
                        },
                        "values": {
                          "MSP": {
                            "mod_policy": "Admins",
                            "value": {
                              "config": {
                                "admins": [],
                                "crypto_config": {
                                  "identity_identifier_hash_function": "SHA256",
                                  "signature_hash_family": "SHA2"
                                },
                                "fabric_node_ous": {
                                  "admin_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNaRENDQWd1Z0F3SUJBZ0lRWUIrbmZaeDlsQjVMSWRvam5rb3Y1akFLQmdncWhrak9QUVFEQWpCOU1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWRNQnNHQTFVRQpDaE1VYlc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZ01CNEdBMVVFCkF4TVhZMkV1Ylc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJd0hoY05NVGt4TURBME1UWXlNakF3V2hjTk1qa3gKTURBeE1UWXlNakF3V2pCOU1Rc3dDUVlEVlFRR0V3SkJVakVOTUFzR0ExVUVDQk1FUTBGQ1FURU5NQXNHQTFVRQpCeE1FUTBGQ1FURWRNQnNHQTFVRUNoTVViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl4RHpBTkJnTlZCQXNUCkJsTkVSMU5KVkRFZ01CNEdBMVVFQXhNWFkyRXViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl3V1RBVEJnY3EKaGtqT1BRSUJCZ2dxaGtqT1BRTUJCd05DQUFRWE4zN1ZoMXdWbmhYRlpDZU1CSUVyYUJnUkN0N0RwWW1TQ0FMbgpNb1FQam12dk1uK3RzT3ovSDFBUTBtYkRTZkVOZStRRmVQQ3ZjN2trTU50YlJxZ1ZvMjB3YXpBT0JnTlZIUThCCkFmOEVCQU1DQWFZd0hRWURWUjBsQkJZd0ZBWUlLd1lCQlFVSEF3SUdDQ3NHQVFVRkJ3TUJNQThHQTFVZEV3RUIKL3dRRk1BTUJBZjh3S1FZRFZSME9CQ0lFSUtQTzZ3bE9jbDJxQTJ1dGlHendaaHVzeTZKMDFWTGRBVmRYUWZ1WgpxMDBFTUFvR0NDcUdTTTQ5QkFNQ0EwY0FNRVFDSUhKNHRmeHFlUUZVNndrcmZEVEZoZ0FWRm4wYVhZT1dsbEd3Ckp2ZGEyWlA2QWlBUjRkZnk3MUNzMGQyTzAyZ2R0TW5tTzlydVJZcnVqbVlDVGtZZ3NITDF6QT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
                                    "organizational_unit_identifier": "admin"
                                  },
                                  "client_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNaRENDQWd1Z0F3SUJBZ0lRWUIrbmZaeDlsQjVMSWRvam5rb3Y1akFLQmdncWhrak9QUVFEQWpCOU1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWRNQnNHQTFVRQpDaE1VYlc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZ01CNEdBMVVFCkF4TVhZMkV1Ylc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJd0hoY05NVGt4TURBME1UWXlNakF3V2hjTk1qa3gKTURBeE1UWXlNakF3V2pCOU1Rc3dDUVlEVlFRR0V3SkJVakVOTUFzR0ExVUVDQk1FUTBGQ1FURU5NQXNHQTFVRQpCeE1FUTBGQ1FURWRNQnNHQTFVRUNoTVViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl4RHpBTkJnTlZCQXNUCkJsTkVSMU5KVkRFZ01CNEdBMVVFQXhNWFkyRXViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl3V1RBVEJnY3EKaGtqT1BRSUJCZ2dxaGtqT1BRTUJCd05DQUFRWE4zN1ZoMXdWbmhYRlpDZU1CSUVyYUJnUkN0N0RwWW1TQ0FMbgpNb1FQam12dk1uK3RzT3ovSDFBUTBtYkRTZkVOZStRRmVQQ3ZjN2trTU50YlJxZ1ZvMjB3YXpBT0JnTlZIUThCCkFmOEVCQU1DQWFZd0hRWURWUjBsQkJZd0ZBWUlLd1lCQlFVSEF3SUdDQ3NHQVFVRkJ3TUJNQThHQTFVZEV3RUIKL3dRRk1BTUJBZjh3S1FZRFZSME9CQ0lFSUtQTzZ3bE9jbDJxQTJ1dGlHendaaHVzeTZKMDFWTGRBVmRYUWZ1WgpxMDBFTUFvR0NDcUdTTTQ5QkFNQ0EwY0FNRVFDSUhKNHRmeHFlUUZVNndrcmZEVEZoZ0FWRm4wYVhZT1dsbEd3Ckp2ZGEyWlA2QWlBUjRkZnk3MUNzMGQyTzAyZ2R0TW5tTzlydVJZcnVqbVlDVGtZZ3NITDF6QT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
                                    "organizational_unit_identifier": "client"
                                  },
                                  "enable": true,
                                  "orderer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNaRENDQWd1Z0F3SUJBZ0lRWUIrbmZaeDlsQjVMSWRvam5rb3Y1akFLQmdncWhrak9QUVFEQWpCOU1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWRNQnNHQTFVRQpDaE1VYlc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZ01CNEdBMVVFCkF4TVhZMkV1Ylc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJd0hoY05NVGt4TURBME1UWXlNakF3V2hjTk1qa3gKTURBeE1UWXlNakF3V2pCOU1Rc3dDUVlEVlFRR0V3SkJVakVOTUFzR0ExVUVDQk1FUTBGQ1FURU5NQXNHQTFVRQpCeE1FUTBGQ1FURWRNQnNHQTFVRUNoTVViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl4RHpBTkJnTlZCQXNUCkJsTkVSMU5KVkRFZ01CNEdBMVVFQXhNWFkyRXViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl3V1RBVEJnY3EKaGtqT1BRSUJCZ2dxaGtqT1BRTUJCd05DQUFRWE4zN1ZoMXdWbmhYRlpDZU1CSUVyYUJnUkN0N0RwWW1TQ0FMbgpNb1FQam12dk1uK3RzT3ovSDFBUTBtYkRTZkVOZStRRmVQQ3ZjN2trTU50YlJxZ1ZvMjB3YXpBT0JnTlZIUThCCkFmOEVCQU1DQWFZd0hRWURWUjBsQkJZd0ZBWUlLd1lCQlFVSEF3SUdDQ3NHQVFVRkJ3TUJNQThHQTFVZEV3RUIKL3dRRk1BTUJBZjh3S1FZRFZSME9CQ0lFSUtQTzZ3bE9jbDJxQTJ1dGlHendaaHVzeTZKMDFWTGRBVmRYUWZ1WgpxMDBFTUFvR0NDcUdTTTQ5QkFNQ0EwY0FNRVFDSUhKNHRmeHFlUUZVNndrcmZEVEZoZ0FWRm4wYVhZT1dsbEd3Ckp2ZGEyWlA2QWlBUjRkZnk3MUNzMGQyTzAyZ2R0TW5tTzlydVJZcnVqbVlDVGtZZ3NITDF6QT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
                                    "organizational_unit_identifier": "orderer"
                                  },
                                  "peer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNaRENDQWd1Z0F3SUJBZ0lRWUIrbmZaeDlsQjVMSWRvam5rb3Y1akFLQmdncWhrak9QUVFEQWpCOU1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWRNQnNHQTFVRQpDaE1VYlc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZ01CNEdBMVVFCkF4TVhZMkV1Ylc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJd0hoY05NVGt4TURBME1UWXlNakF3V2hjTk1qa3gKTURBeE1UWXlNakF3V2pCOU1Rc3dDUVlEVlFRR0V3SkJVakVOTUFzR0ExVUVDQk1FUTBGQ1FURU5NQXNHQTFVRQpCeE1FUTBGQ1FURWRNQnNHQTFVRUNoTVViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl4RHpBTkJnTlZCQXNUCkJsTkVSMU5KVkRFZ01CNEdBMVVFQXhNWFkyRXViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl3V1RBVEJnY3EKaGtqT1BRSUJCZ2dxaGtqT1BRTUJCd05DQUFRWE4zN1ZoMXdWbmhYRlpDZU1CSUVyYUJnUkN0N0RwWW1TQ0FMbgpNb1FQam12dk1uK3RzT3ovSDFBUTBtYkRTZkVOZStRRmVQQ3ZjN2trTU50YlJxZ1ZvMjB3YXpBT0JnTlZIUThCCkFmOEVCQU1DQWFZd0hRWURWUjBsQkJZd0ZBWUlLd1lCQlFVSEF3SUdDQ3NHQVFVRkJ3TUJNQThHQTFVZEV3RUIKL3dRRk1BTUJBZjh3S1FZRFZSME9CQ0lFSUtQTzZ3bE9jbDJxQTJ1dGlHendaaHVzeTZKMDFWTGRBVmRYUWZ1WgpxMDBFTUFvR0NDcUdTTTQ5QkFNQ0EwY0FNRVFDSUhKNHRmeHFlUUZVNndrcmZEVEZoZ0FWRm4wYVhZT1dsbEd3Ckp2ZGEyWlA2QWlBUjRkZnk3MUNzMGQyTzAyZ2R0TW5tTzlydVJZcnVqbVlDVGtZZ3NITDF6QT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
                                    "organizational_unit_identifier": "peer"
                                  }
                                },
                                "intermediate_certs": [],
                                "name": "MORGS",
                                "organizational_unit_identifiers": [],
                                "revocation_list": [],
                                "root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNaRENDQWd1Z0F3SUJBZ0lRWUIrbmZaeDlsQjVMSWRvam5rb3Y1akFLQmdncWhrak9QUVFEQWpCOU1Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWRNQnNHQTFVRQpDaE1VYlc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZ01CNEdBMVVFCkF4TVhZMkV1Ylc5eVozTXVkSEpwWW1abFpDNW5iMkl1WVhJd0hoY05NVGt4TURBME1UWXlNakF3V2hjTk1qa3gKTURBeE1UWXlNakF3V2pCOU1Rc3dDUVlEVlFRR0V3SkJVakVOTUFzR0ExVUVDQk1FUTBGQ1FURU5NQXNHQTFVRQpCeE1FUTBGQ1FURWRNQnNHQTFVRUNoTVViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl4RHpBTkJnTlZCQXNUCkJsTkVSMU5KVkRFZ01CNEdBMVVFQXhNWFkyRXViVzl5WjNNdWRISnBZbVpsWkM1bmIySXVZWEl3V1RBVEJnY3EKaGtqT1BRSUJCZ2dxaGtqT1BRTUJCd05DQUFRWE4zN1ZoMXdWbmhYRlpDZU1CSUVyYUJnUkN0N0RwWW1TQ0FMbgpNb1FQam12dk1uK3RzT3ovSDFBUTBtYkRTZkVOZStRRmVQQ3ZjN2trTU50YlJxZ1ZvMjB3YXpBT0JnTlZIUThCCkFmOEVCQU1DQWFZd0hRWURWUjBsQkJZd0ZBWUlLd1lCQlFVSEF3SUdDQ3NHQVFVRkJ3TUJNQThHQTFVZEV3RUIKL3dRRk1BTUJBZjh3S1FZRFZSME9CQ0lFSUtQTzZ3bE9jbDJxQTJ1dGlHendaaHVzeTZKMDFWTGRBVmRYUWZ1WgpxMDBFTUFvR0NDcUdTTTQ5QkFNQ0EwY0FNRVFDSUhKNHRmeHFlUUZVNndrcmZEVEZoZ0FWRm4wYVhZT1dsbEd3Ckp2ZGEyWlA2QWlBUjRkZnk3MUNzMGQyTzAyZ2R0TW5tTzlydVJZcnVqbVlDVGtZZ3NITDF6QT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
                                ],
                                "signing_identity": null,
                                "tls_intermediate_certs": [],
                                "tls_root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNiVENDQWhTZ0F3SUJBZ0lSQU9IL0FmY2h0VFpYdUd5N0JKTW5qVzh3Q2dZSUtvWkl6ajBFQXdJd2dZQXgKQ3pBSkJnTlZCQVlUQWtGU01RMHdDd1lEVlFRSUV3UkRRVUpCTVEwd0N3WURWUVFIRXdSRFFVSkJNUjB3R3dZRApWUVFLRXhSdGIzSm5jeTUwY21saVptVmtMbWR2WWk1aGNqRVBNQTBHQTFVRUN4TUdVMFJIVTBsVU1TTXdJUVlEClZRUURFeHAwYkhOallTNXRiM0puY3k1MGNtbGlabVZrTG1kdllpNWhjakFlRncweE9URXdNRFF4TmpJeU1EQmEKRncweU9URXdNREV4TmpJeU1EQmFNSUdBTVFzd0NRWURWUVFHRXdKQlVqRU5NQXNHQTFVRUNCTUVRMEZDUVRFTgpNQXNHQTFVRUJ4TUVRMEZDUVRFZE1Cc0dBMVVFQ2hNVWJXOXlaM011ZEhKcFltWmxaQzVuYjJJdVlYSXhEekFOCkJnTlZCQXNUQmxORVIxTkpWREVqTUNFR0ExVUVBeE1hZEd4elkyRXViVzl5WjNNdWRISnBZbVpsWkM1bmIySXUKWVhJd1dUQVRCZ2NxaGtqT1BRSUJCZ2dxaGtqT1BRTUJCd05DQUFUdjhwdlRyYWdZMzJqS3NRelpNdS8wNHhHYgp0TjNoR3RsbjVnRnRjZHVIbG1jK1hnRXoxRVh2cWZKaEl0emQ1R3FxUll1bkZuV3duMUdKT1YvWTAwQVlvMjB3CmF6QU9CZ05WSFE4QkFmOEVCQU1DQWFZd0hRWURWUjBsQkJZd0ZBWUlLd1lCQlFVSEF3SUdDQ3NHQVFVRkJ3TUIKTUE4R0ExVWRFd0VCL3dRRk1BTUJBZjh3S1FZRFZSME9CQ0lFSU81UXlVaVhHdm9NZ1FheWhaRnN6YWNMZ1lDNwp1VGhxRUVsVGp1THduVmxiTUFvR0NDcUdTTTQ5QkFNQ0EwY0FNRVFDSUJEYlVCcTlXQXdqbnpzQkFua0lnRnZQCnBHT0w2NEhHd3FXb29kOGJwc0F6QWlBdWFDWjVCc0ZBaXhTR3ExOGxGQThuYmE3RVFQdTcxZ0ZOcUhUL042eXEKTUE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                                ]
                              },
                              "type": 0
                            },
                            "version": "0"
                          }
                        },
                        "version": "0"
                      }
                    },
                    "mod_policy": "Admins",
                    "policies": {
                      "Admins": {
                        "mod_policy": "Admins",
                        "policy": {
                          "type": 3,
                          "value": {
                            "rule": "MAJORITY",
                            "sub_policy": "Admins"
                          }
                        },
                        "version": "0"
                      },
                      "Readers": {
                        "mod_policy": "Admins",
                        "policy": {
                          "type": 3,
                          "value": {
                            "rule": "ANY",
                            "sub_policy": "Readers"
                          }
                        },
                        "version": "0"
                      },
                      "Writers": {
                        "mod_policy": "Admins",
                        "policy": {
                          "type": 3,
                          "value": {
                            "rule": "ANY",
                            "sub_policy": "Writers"
                          }
                        },
                        "version": "0"
                      }
                    },
                    "values": {
                      "Capabilities": {
                        "mod_policy": "Admins",
                        "value": {
                          "capabilities": {
                            "V1_4_2": {}
                          }
                        },
                        "version": "0"
                      }
                    },
                    "version": "1"
                  },
                  "Orderer": {
                    "groups": {
                      "AFIP": {
                        "groups": {},
                        "mod_policy": "Admins",
                        "policies": {
                          "Admins": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Readers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "ADMIN"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "CLIENT"
                                    },
                                    "principal_classification": "ROLE"
                                  },
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "PEER"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      },
                                      {
                                        "signed_by": 1
                                      },
                                      {
                                        "signed_by": 2
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          },
                          "Writers": {
                            "mod_policy": "Admins",
                            "policy": {
                              "type": 1,
                              "value": {
                                "identities": [
                                  {
                                    "principal": {
                                      "msp_identifier": "AFIP",
                                      "role": "MEMBER"
                                    },
                                    "principal_classification": "ROLE"
                                  }
                                ],
                                "rule": {
                                  "n_out_of": {
                                    "n": 1,
                                    "rules": [
                                      {
                                        "signed_by": 0
                                      }
                                    ]
                                  }
                                },
                                "version": 0
                              }
                            },
                            "version": "0"
                          }
                        },
                        "values": {
                          "MSP": {
                            "mod_policy": "Admins",
                            "value": {
                              "config": {
                                "admins": [],
                                "crypto_config": {
                                  "identity_identifier_hash_function": "SHA256",
                                  "signature_hash_family": "SHA2"
                                },
                                "fabric_node_ous": {
                                  "admin_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "admin"
                                  },
                                  "client_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "client"
                                  },
                                  "enable": true,
                                  "orderer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "orderer"
                                  },
                                  "peer_ou_identifier": {
                                    "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
                                    "organizational_unit_identifier": "peer"
                                  }
                                },
                                "intermediate_certs": [],
                                "name": "AFIP",
 																"organizational_unit_identifiers": [ 
                                  {
																		"certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
																		"organizational_unit_identifier": "MSP-TRIBUTARIA"
																	}
																],
                                "revocation_list": [],
                                "root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
                                ],
                                "signing_identity": null,
                                "tls_intermediate_certs": [],
                                "tls_root_certs": [
                                  "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNhRENDQWc2Z0F3SUJBZ0lSQUxZeVBKeU9GcTkxR01vb2FFQmdjVUl3Q2dZSUtvWkl6ajBFQXdJd2ZqRUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFaU1DQUdBMVVFCkF4TVpkR3h6WTJFdVlXWnBjQzUwY21saVptVmtMbWR2WWk1aGNqQWVGdzB4T1RFd01EUXhOakl5TURCYUZ3MHkKT1RFd01ERXhOakl5TURCYU1INHhDekFKQmdOVkJBWVRBa0ZTTVEwd0N3WURWUVFJRXdSRFFVSkJNUTB3Q3dZRApWUVFIRXdSRFFVSkJNUnd3R2dZRFZRUUtFeE5oWm1sd0xuUnlhV0ptWldRdVoyOWlMbUZ5TVE4d0RRWURWUVFMCkV3WlRSRWRUU1ZReElqQWdCZ05WQkFNVEdYUnNjMk5oTG1GbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJd1dUQVQKQmdjcWhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FBU0R5OUhUUHIrSzM2N1hEazd3dm4yRHlZYVZsZlY2Y2V4Vwp3MlNJRk9PdE13Zlg0aGJ5bDNqYnBLK0IyMy8xMUFoQ3BVMit0M3pNRXlhdFNCTDJVVEV4bzIwd2F6QU9CZ05WCkhROEJBZjhFQkFNQ0FhWXdIUVlEVlIwbEJCWXdGQVlJS3dZQkJRVUhBd0lHQ0NzR0FRVUZCd01CTUE4R0ExVWQKRXdFQi93UUZNQU1CQWY4d0tRWURWUjBPQkNJRUlEL0R4MGxEVExBZ2haNVFsQUQrOXgwaW4rUStST1QyclhxegpWd1ZqeTNYSk1Bb0dDQ3FHU000OUJBTUNBMGdBTUVVQ0lRQzJzR2M5MnpqM2Ntd082bFRpRWViYjAyQ0thRnhJCkx0ZnRsQm5nWW5OY1NRSWdSQ1EwYUdjeGFoaUlmNnlNRHoxV1VDSkZBVHU2d2Y1eFErMGR1TXFReFg4PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                                ]
                              },
                              "type": 0
                            },
                            "version": "0"
                          }
                        },
                        "version": "0"
                      }
                    },
                    "mod_policy": "Admins",
                    "policies": {
                      "Admins": {
                        "mod_policy": "Admins",
                        "policy": {
                          "type": 3,
                          "value": {
                            "rule": "MAJORITY",
                            "sub_policy": "Admins"
                          }
                        },
                        "version": "0"
                      },
                      "BlockValidation": {
                        "mod_policy": "Admins",
                        "policy": {
                          "type": 3,
                          "value": {
                            "rule": "ANY",
                            "sub_policy": "Writers"
                          }
                        },
                        "version": "0"
                      },
                      "Readers": {
                        "mod_policy": "Admins",
                        "policy": {
                          "type": 3,
                          "value": {
                            "rule": "ANY",
                            "sub_policy": "Readers"
                          }
                        },
                        "version": "0"
                      },
                      "Writers": {
                        "mod_policy": "Admins",
                        "policy": {
                          "type": 3,
                          "value": {
                            "rule": "ANY",
                            "sub_policy": "Writers"
                          }
                        },
                        "version": "0"
                      }
                    },
                    "values": {
                      "BatchSize": {
                        "mod_policy": "Admins",
                        "value": {
                          "absolute_max_bytes": 5242880,
                          "max_message_count": 1000,
                          "preferred_max_bytes": 4194304
                        },
                        "version": "0"
                      },
                      "BatchTimeout": {
                        "mod_policy": "Admins",
                        "value": {
                          "timeout": "2s"
                        },
                        "version": "0"
                      },
                      "Capabilities": {
                        "mod_policy": "Admins",
                        "value": {
                          "capabilities": {
                            "V1_4_2": {}
                          }
                        },
                        "version": "0"
                      },
                      "ChannelRestrictions": {
                        "mod_policy": "Admins",
                        "value": null,
                        "version": "0"
                      },
                      "ConsensusType": {
                        "mod_policy": "Admins",
                        "value": {
                          "metadata": {
                            "consenters": [
                              {
                                "client_tls_cert": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNmVENDQWlPZ0F3SUJBZ0lRQWxwN0RrSDhLVXFCOWxUWVlYdGVyVEFLQmdncWhrak9QUVFEQWpCK01Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWNNQm9HQTFVRQpDaE1UWVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pFUE1BMEdBMVVFQ3hNR1UwUkhVMGxVTVNJd0lBWURWUVFECkV4bDBiSE5qWVM1aFptbHdMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTJNakl3TUZvWERUSTUKTVRBd01URTJNakl3TUZvd1lqRUxNQWtHQTFVRUJoTUNRVkl4RFRBTEJnTlZCQWdUQkVOQlFrRXhEVEFMQmdOVgpCQWNUQkVOQlFrRXhEekFOQmdOVkJBc1RCbE5FUjFOSlZERWtNQ0lHQTFVRUF4TWJiM0prWlhKbGNpNWhabWx3CkxuUnlhV0ptWldRdVoyOWlMbUZ5TUZrd0V3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFcmtUQ2d0L1AKcTU4KzVTUHFmOGtraFNQM1NiZ1g3MzlNMk0vTExTMXNCVTh2VUJCalNZV2VtMlhqNVVXYmN0Y3QycjlaOHM1VQpJWlJDNXpUWDVqYWZZcU9CbmpDQm16QU9CZ05WSFE4QkFmOEVCQU1DQmFBd0hRWURWUjBsQkJZd0ZBWUlLd1lCCkJRVUhBd0VHQ0NzR0FRVUZCd01DTUF3R0ExVWRFd0VCL3dRQ01BQXdLd1lEVlIwakJDUXdJb0FnUDhQSFNVTk0Kc0NDRm5sQ1VBUDczSFNLZjVENUU1UGF0ZXJOWEJXUExkY2t3THdZRFZSMFJCQ2d3Sm9JYmIzSmtaWEpsY2k1aApabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlnZ2R2Y21SbGNtVnlNQW9HQ0NxR1NNNDlCQU1DQTBnQU1FVUNJUUQ0Cnl5bGlYZDRPaHJpNFA3SG8wMGNBeXFBUXA3azZZdCtZMmwxVmJWbTM4Z0lnTTVWVHhUTEtmeWY4UlNCaTN3SWcKSmJMZVlQeHhjRkFyNzhMVGNWcVhtMTA9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
                                "host": "orderer0.afip.tribfed.gob.ar",
                                "port": 7050,
                                "server_tls_cert": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNmVENDQWlPZ0F3SUJBZ0lRQWxwN0RrSDhLVXFCOWxUWVlYdGVyVEFLQmdncWhrak9QUVFEQWpCK01Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWNNQm9HQTFVRQpDaE1UWVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pFUE1BMEdBMVVFQ3hNR1UwUkhVMGxVTVNJd0lBWURWUVFECkV4bDBiSE5qWVM1aFptbHdMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTJNakl3TUZvWERUSTUKTVRBd01URTJNakl3TUZvd1lqRUxNQWtHQTFVRUJoTUNRVkl4RFRBTEJnTlZCQWdUQkVOQlFrRXhEVEFMQmdOVgpCQWNUQkVOQlFrRXhEekFOQmdOVkJBc1RCbE5FUjFOSlZERWtNQ0lHQTFVRUF4TWJiM0prWlhKbGNpNWhabWx3CkxuUnlhV0ptWldRdVoyOWlMbUZ5TUZrd0V3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFcmtUQ2d0L1AKcTU4KzVTUHFmOGtraFNQM1NiZ1g3MzlNMk0vTExTMXNCVTh2VUJCalNZV2VtMlhqNVVXYmN0Y3QycjlaOHM1VQpJWlJDNXpUWDVqYWZZcU9CbmpDQm16QU9CZ05WSFE4QkFmOEVCQU1DQmFBd0hRWURWUjBsQkJZd0ZBWUlLd1lCCkJRVUhBd0VHQ0NzR0FRVUZCd01DTUF3R0ExVWRFd0VCL3dRQ01BQXdLd1lEVlIwakJDUXdJb0FnUDhQSFNVTk0Kc0NDRm5sQ1VBUDczSFNLZjVENUU1UGF0ZXJOWEJXUExkY2t3THdZRFZSMFJCQ2d3Sm9JYmIzSmtaWEpsY2k1aApabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlnZ2R2Y21SbGNtVnlNQW9HQ0NxR1NNNDlCQU1DQTBnQU1FVUNJUUQ0Cnl5bGlYZDRPaHJpNFA3SG8wMGNBeXFBUXA3azZZdCtZMmwxVmJWbTM4Z0lnTTVWVHhUTEtmeWY4UlNCaTN3SWcKSmJMZVlQeHhjRkFyNzhMVGNWcVhtMTA9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
                              }
                            ],
                            "options": {
                              "election_tick": 10,
                              "heartbeat_tick": 1,
                              "max_inflight_blocks": 5,
                              "snapshot_interval_size": 20971520,
                              "tick_interval": "500ms"
                            }
                          },
                          "state": "STATE_NORMAL",
                          "type": "etcdraft"
                        },
                        "version": "0"
                      }
                    },
                    "version": "0"
                  }
                },
                "mod_policy": "Admins",
                "policies": {
                  "Admins": {
                    "mod_policy": "Admins",
                    "policy": {
                      "type": 3,
                      "value": {
                        "rule": "MAJORITY",
                        "sub_policy": "Admins"
                      }
                    },
                    "version": "0"
                  },
                  "Readers": {
                    "mod_policy": "Admins",
                    "policy": {
                      "type": 3,
                      "value": {
                        "rule": "ANY",
                        "sub_policy": "Readers"
                      }
                    },
                    "version": "0"
                  },
                  "Writers": {
                    "mod_policy": "Admins",
                    "policy": {
                      "type": 3,
                      "value": {
                        "rule": "ANY",
                        "sub_policy": "Writers"
                      }
                    },
                    "version": "0"
                  }
                },
                "values": {
                  "BlockDataHashingStructure": {
                    "mod_policy": "Admins",
                    "value": {
                      "width": 4294967295
                    },
                    "version": "0"
                  },
                  "Capabilities": {
                    "mod_policy": "Admins",
                    "value": {
                      "capabilities": {
                        "V1_3": {},
                        "V1_4_3": {}
                      }
                    },
                    "version": "0"
                  },
                  "Consortium": {
                    "mod_policy": "Admins",
                    "value": {
                      "name": "TaxConsortium"
                    },
                    "version": "0"
                  },
                  "HashingAlgorithm": {
                    "mod_policy": "Admins",
                    "value": {
                      "name": "SHA256"
                    },
                    "version": "0"
                  },
                  "OrdererAddresses": {
                    "mod_policy": "/Channel/Orderer/Admins",
                    "value": {
                      "addresses": [
                        "orderer.afip.tribfed.gob.ar:7050"
                      ]
                    },
                    "version": "0"
                  }
                },
                "version": "0"
              },
              "sequence": "4"
            },
            "last_update": {
              "payload": {
                "data": {
                  "config_update": {
                    "channel_id": "padfedchannel",
                    "isolated_data": {},
                    "read_set": {
                      "groups": {
                        "Application": {
                          "groups": {
                            "ARBA": {
                              "groups": {},
                              "mod_policy": "",
                              "policies": {
                                "Admins": {
                                  "mod_policy": "",
                                  "policy": null,
                                  "version": "0"
                                },
                                "Readers": {
                                  "mod_policy": "",
                                  "policy": null,
                                  "version": "0"
                                },
                                "Writers": {
                                  "mod_policy": "",
                                  "policy": null,
                                  "version": "0"
                                }
                              },
                              "values": {
                                "MSP": {
                                  "mod_policy": "",
                                  "value": null,
                                  "version": "0"
                                }
                              },
                              "version": "0"
                            }
                          },
                          "mod_policy": "Admins",
                          "policies": {},
                          "values": {},
                          "version": "1"
                        }
                      },
                      "mod_policy": "",
                      "policies": {},
                      "values": {},
                      "version": "0"
                    },
                    "write_set": {
                      "groups": {
                        "Application": {
                          "groups": {
                            "ARBA": {
                              "groups": {},
                              "mod_policy": "Admins",
                              "policies": {
                                "Admins": {
                                  "mod_policy": "",
                                  "policy": null,
                                  "version": "0"
                                },
                                "Readers": {
                                  "mod_policy": "",
                                  "policy": null,
                                  "version": "0"
                                },
                                "Writers": {
                                  "mod_policy": "",
                                  "policy": null,
                                  "version": "0"
                                }
                              },
                              "values": {
                                "AnchorPeers": {
                                  "mod_policy": "Admins",
                                  "value": {
                                    "anchor_peers": [
                                      {
                                        "host": "peer0.arba.tribfed.gob.ar",
                                        "port": 7051
                                      }
                                    ]
                                  },
                                  "version": "0"
                                },
                                "MSP": {
                                  "mod_policy": "",
                                  "value": null,
                                  "version": "0"
                                }
                              },
                              "version": "1"
                            }
                          },
                          "mod_policy": "Admins",
                          "policies": {},
                          "values": {},
                          "version": "1"
                        }
                      },
                      "mod_policy": "",
                      "policies": {},
                      "values": {},
                      "version": "0"
                    }
                  },
                  "signatures": [
                    {
                      "signature": "MEQCIEhp+V+S9L3IrbOMM8gQJkPWKRGg8QYRxThOEkZJiCCbAiAHgqmRdDKnl+hNeb9GhoefRdsRlOnwVz4PJYz5c2zTHw==",
                      "signature_header": {
                        "creator": {
                          "id_bytes": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNTVENDQWZDZ0F3SUJBZ0lSQVBmZjRZcGFkSHhXYnB4ZHhWWDBsSTB3Q2dZSUtvWkl6ajBFQXdJd2dZVXgKQ3pBSkJnTlZCQVlUQWtGU01SVXdFd1lEVlFRSUV3eENkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aApJRkJzWVhSaE1Sd3dHZ1lEVlFRS0V4TmhjbUpoTG5SeWFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIClIxUkpNUjh3SFFZRFZRUURFeFpqWVM1aGNtSmhMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTIKTWpJd01Gb1hEVEk1TVRBd01URTJNakl3TUZvd2VERUxNQWtHQTFVRUJoTUNRVkl4RlRBVEJnTlZCQWdUREVKMQpaVzV2Y3lCQmFYSmxjekVSTUE4R0ExVUVCeE1JVEdFZ1VHeGhkR0V4R3pBTEJnTlZCQXNUQkVkSFZFa3dEQVlEClZRUUxFd1ZoWkcxcGJqRWlNQ0FHQTFVRUF3d1pRV1J0YVc1QVlYSmlZUzUwY21saVptVmtMbWR2WWk1aGNqQloKTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEEwSUFCQ0tvbGZUajcxWEowL1licStmTUgwRTRRS3AyMUM4RQpKeTJCSFFjRW8wMlNNZmxpUEpjMVJUZ0VQYTBGSXZCU1A5K3dXVnppL0dBUVc1RS92bGpWSGFDalRUQkxNQTRHCkExVWREd0VCL3dRRUF3SUhnREFNQmdOVkhSTUJBZjhFQWpBQU1Dc0dBMVVkSXdRa01DS0FJSmFSM2RGWGtJYkMKbFJ3c09kMkpqcE54MlpZSGgzc3dhZ2JEVFNJQTVwSTZNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJSEIvNFViaQpXVkxMdGgwMjRQVlp3LzdhcHJVWFNnY3V3SzZtN0hIQ3VXeXJBaUJNYkllTFB4emZCSEF5cEpqZmVJRVpnMTlUCi91R3JZZTR4WnAvVldFZDJ4QT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
                          "mspid": "ARBA"
                        },
                        "nonce": "bd8p/pYczWU/iWrhVWWme+CcoCtlTslR"
                      }
                    }
                  ]
                },
                "header": {
                  "channel_header": {
                    "channel_id": "padfedchannel",
                    "epoch": "0",
                    "extension": null,
                    "timestamp": "2019-10-04T16:28:23Z",
                    "tls_cert_hash": null,
                    "tx_id": "",
                    "type": 2,
                    "version": 0
                  },
                  "signature_header": {
                    "creator": {
                      "id_bytes": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNTVENDQWZDZ0F3SUJBZ0lSQVBmZjRZcGFkSHhXYnB4ZHhWWDBsSTB3Q2dZSUtvWkl6ajBFQXdJd2dZVXgKQ3pBSkJnTlZCQVlUQWtGU01SVXdFd1lEVlFRSUV3eENkV1Z1YjNNZ1FXbHlaWE14RVRBUEJnTlZCQWNUQ0V4aApJRkJzWVhSaE1Sd3dHZ1lEVlFRS0V4TmhjbUpoTG5SeWFXSm1aV1F1WjI5aUxtRnlNUTB3Q3dZRFZRUUxFd1JIClIxUkpNUjh3SFFZRFZRUURFeFpqWVM1aGNtSmhMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTIKTWpJd01Gb1hEVEk1TVRBd01URTJNakl3TUZvd2VERUxNQWtHQTFVRUJoTUNRVkl4RlRBVEJnTlZCQWdUREVKMQpaVzV2Y3lCQmFYSmxjekVSTUE4R0ExVUVCeE1JVEdFZ1VHeGhkR0V4R3pBTEJnTlZCQXNUQkVkSFZFa3dEQVlEClZRUUxFd1ZoWkcxcGJqRWlNQ0FHQTFVRUF3d1pRV1J0YVc1QVlYSmlZUzUwY21saVptVmtMbWR2WWk1aGNqQloKTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEEwSUFCQ0tvbGZUajcxWEowL1licStmTUgwRTRRS3AyMUM4RQpKeTJCSFFjRW8wMlNNZmxpUEpjMVJUZ0VQYTBGSXZCU1A5K3dXVnppL0dBUVc1RS92bGpWSGFDalRUQkxNQTRHCkExVWREd0VCL3dRRUF3SUhnREFNQmdOVkhSTUJBZjhFQWpBQU1Dc0dBMVVkSXdRa01DS0FJSmFSM2RGWGtJYkMKbFJ3c09kMkpqcE54MlpZSGgzc3dhZ2JEVFNJQTVwSTZNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJSEIvNFViaQpXVkxMdGgwMjRQVlp3LzdhcHJVWFNnY3V3SzZtN0hIQ3VXeXJBaUJNYkllTFB4emZCSEF5cEpqZmVJRVpnMTlUCi91R3JZZTR4WnAvVldFZDJ4QT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
                      "mspid": "ARBA"
                    },
                    "nonce": "qPhCkF6mIx02Mfm8KQCua8DiTC6bgaXg"
                  }
                }
              },
              "signature": "MEUCIQDTI0yjsZmZtpHo3uEHTmZieq7lQD3fVFerZtrpJaJPKgIgE66h078uwXIrj26h9e+9UsQb1E3/8H5H0WmYqlcn420="
            }
          },
          "header": {
            "channel_header": {
              "channel_id": "padfedchannel",
              "epoch": "0",
              "extension": null,
              "timestamp": "2019-10-04T16:28:23Z",
              "tls_cert_hash": null,
              "tx_id": "",
              "type": 1,
              "version": 0
            },
            "signature_header": {
              "creator": {
                "id_bytes": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNOVENDQWR5Z0F3SUJBZ0lSQUlla0VSZHpIVDc1YXgrQWlzbWtOcm93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUc4eEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dEUVlEVlFRTEV3WlRSRWRUU1ZRd0N3WURWUVFMRXdSd1pXVnlNU1F3SWdZRFZRUURFeHR2CmNtUmxjbVZ5TG1GbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJd1dUQVRCZ2NxaGtqT1BRSUJCZ2dxaGtqT1BRTUIKQndOQ0FBVGJaV3BzQlh5RVVKM010a0ZDOHRQNHlVY1lESkJyQzlMdkFWaWJJRkFmZkVZREFuTGltZXhZUkkyawo0QTJobUFMSUdFVXJhZ3N4NHVTVStRb0plMGw5bzAwd1N6QU9CZ05WSFE4QkFmOEVCQU1DQjRBd0RBWURWUjBUCkFRSC9CQUl3QURBckJnTlZIU01FSkRBaWdDQ1JqcmpLNm9oRytyZG10eW5DdVhXZjZETUtmZXNyNU5WMTkrcXEKdTE4djh6QUtCZ2dxaGtqT1BRUURBZ05IQURCRUFpQnIrOFpzS0dyS0FUY1dlUFp0SUNrR3ZPYmJ6RzVJeThIRgorQ3VrRlkySlZnSWdBVjlvcGVpZkFseEx3OXZhcklYSmNhNmp2UFJEYm43WnB3NFByQWJBRXk0PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==",
                "mspid": "AFIP"
              },
              "nonce": "U0GAtVBcz19ndXLhkfjGfsNDkI1V9naQ"
            }
          }
        },
        "signature": "MEMCIAf4HvZAWb6cG+f0VqfE0w9Fk4/AMDSfJQ+g6+IsUc+BAh8SmK8ba3NUMyYYQdx2wtChviVc6FOl9Z48pZja5/VH"
      }
    ]
  },
  "header": {
    "data_hash": "R9GAjNr31QRTwItaPRewDm/plTsGwk1DDNEBDC95q2o=",
    "number": "3",
    "previous_hash": "O5rRII77g2B9IaxttwoBM1x1T/gAEl610NnbZb9FY8E="
  },
  "metadata": {
    "metadata": [
      "Cg8KAggDEgkKBwoBARACGAUSqwcK4AYKwwYKBEFGSVASugYtLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KTUlJQ05UQ0NBZHlnQXdJQkFnSVJBSWVrRVJkekhUNzVheCtBaXNta05yb3dDZ1lJS29aSXpqMEVBd0l3ZXpFTApNQWtHQTFVRUJoTUNRVkl4RFRBTEJnTlZCQWdUQkVOQlFrRXhEVEFMQmdOVkJBY1RCRU5CUWtFeEhEQWFCZ05WCkJBb1RFMkZtYVhBdWRISnBZbVpsWkM1bmIySXVZWEl4RHpBTkJnTlZCQXNUQmxORVIxTkpWREVmTUIwR0ExVUUKQXhNV1kyRXVZV1pwY0M1MGNtbGlabVZrTG1kdllpNWhjakFlRncweE9URXdNRFF4TmpJeU1EQmFGdzB5T1RFdwpNREV4TmpJeU1EQmFNRzh4Q3pBSkJnTlZCQVlUQWtGU01RMHdDd1lEVlFRSUV3UkRRVUpCTVEwd0N3WURWUVFICkV3UkRRVUpCTVJ3d0RRWURWUVFMRXdaVFJFZFRTVlF3Q3dZRFZRUUxFd1J3WldWeU1TUXdJZ1lEVlFRREV4dHYKY21SbGNtVnlMbUZtYVhBdWRISnBZbVpsWkM1bmIySXVZWEl3V1RBVEJnY3Foa2pPUFFJQkJnZ3Foa2pPUFFNQgpCd05DQUFUYlpXcHNCWHlFVUozTXRrRkM4dFA0eVVjWURKQnJDOUx2QVZpYklGQWZmRVlEQW5MaW1leFlSSTJrCjRBMmhtQUxJR0VVcmFnc3g0dVNVK1FvSmUwbDlvMDB3U3pBT0JnTlZIUThCQWY4RUJBTUNCNEF3REFZRFZSMFQKQVFIL0JBSXdBREFyQmdOVkhTTUVKREFpZ0NDUmpyaks2b2hHK3JkbXR5bkN1WFdmNkRNS2Zlc3I1TlYxOStxcQp1MTh2OHpBS0JnZ3Foa2pPUFFRREFnTkhBREJFQWlCcis4WnNLR3JLQVRjV2VQWnRJQ2tHdk9iYnpHNUl5OEhGCitDdWtGWTJKVmdJZ0FWOW9wZWlmQWx4THc5dmFySVhKY2E2anZQUkRibjdacHc0UHJBYkFFeTQ9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KEhj9agbeuRsks7lSlhfw8ZcrBjfHlx7A418SRjBEAiBfstGo9w39Msto/Ah86O4gc7mc1xbjSsySTd8Dv3Y0nAIga/rANMgH3iDpYbQPTMEqx5NFpJRTA3XfC7tyvMmxNRo=",
      "CgIIAw==",
      "AA==",
      "CgcKAQEQAhgF",
      "CiA3vlMyuTAO8uMB8ODlOFoKcp0/71yepKe9R2a7kZmKMQ=="
    ]
  }
}
'

readonly ORGX_JSON='
{   
	"groups": {},
	"mod_policy": "Admins",
	"policies": {
		"Admins": {
			"mod_policy": "Admins",
			"policy": {
				"type": 1,
				"value": {
					"identities": [
						{
							"principal": {
							"msp_identifier": "ORGX",
							"role": "ADMIN"
							},
							"principal_classification": "ROLE"
						}
					],
					"rule": {
						"n_out_of": {
							"n": 1,
							"rules": [
							{
							"signed_by": 0
							}
							]
						}
					},
					"version": 0
				}
			},
			"version": "0"
		},
		"Readers": {
			"mod_policy": "Admins",
			"policy": {
				"type": 1,
				"value": {
					"identities": [
						{
							"principal": {
							"msp_identifier": "ORGX",
							"role": "ADMIN"
							},
							"principal_classification": "ROLE"
						},
						{
							"principal": {
							"msp_identifier": "ORGX",
							"role": "CLIENT"
							},
							"principal_classification": "ROLE"
						},
						{
							"principal": {
							"msp_identifier": "ORGX",
							"role": "PEER"
							},
							"principal_classification": "ROLE"
						}
					],
					"rule": {
						"n_out_of": {
							"n": 1,
							"rules": [
							{
							"signed_by": 0
							},
							{
							"signed_by": 1
							},
							{
							"signed_by": 2
							}
							]
						}
					},
					"version": 0
				}
			},
			"version": "0"
		},
		"Writers": {
			"mod_policy": "Admins",
			"policy": {
				"type": 1,
				"value": {
					"identities": [
						{
							"principal": {
							"msp_identifier": "ORGX",
							"role": "MEMBER"
							},
							"principal_classification": "ROLE"
						}
					],
					"rule": {
						"n_out_of": {
							"n": 1,
							"rules": [
							{
							"signed_by": 0
							}
							]
						}
					},
					"version": 0
				}
			},
			"version": "0"
		}
	},
	"values": {
		"MSP": {
			"mod_policy": "Admins",
			"value": {
				"config": {
					"admins": [],
					"crypto_config": {
						"identity_identifier_hash_function": "SHA256",
						"signature_hash_family": "SHA2"
					},
					"fabric_node_ous": {
						"admin_ou_identifier": {
							"certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUxZYk1sbGtsaXc4b21FREYvek1ZM3N3Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEE1TWpneE56RXdNREJhRncweU9UQTUKTWpVeE56RXdNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVIrY2ZaNHJqc2w2d3BjQWlZNzA4cFJWdlNuYytWNHBrN1Z3UW1EMVZqUwowOXErNUR3dWpma3BXYnIxY0l4ZVM0amlsbHV0OUcwSmMxWlowL2ZCc3FjRW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJQldYd0RDeGtMOHB2YnFtMHhIVFJhRlh1NEpPUDZEMWRKTDNuK2NNcTJISgpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJQjVpNEtldFp6S1ArY0FHcEEwUlpjcnRWd0hISnlvOHZDdEN1L2FzCkpDb1ZBaUJseGNPL0kyNTVYbHIrdkxldkl6dE9zZzFEaU9mNDVYZ2prVFQwaktBUWJBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
							"organizational_unit_identifier": "admin"
						},
						"client_ou_identifier": {
							"certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUxZYk1sbGtsaXc4b21FREYvek1ZM3N3Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEE1TWpneE56RXdNREJhRncweU9UQTUKTWpVeE56RXdNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVIrY2ZaNHJqc2w2d3BjQWlZNzA4cFJWdlNuYytWNHBrN1Z3UW1EMVZqUwowOXErNUR3dWpma3BXYnIxY0l4ZVM0amlsbHV0OUcwSmMxWlowL2ZCc3FjRW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJQldYd0RDeGtMOHB2YnFtMHhIVFJhRlh1NEpPUDZEMWRKTDNuK2NNcTJISgpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJQjVpNEtldFp6S1ArY0FHcEEwUlpjcnRWd0hISnlvOHZDdEN1L2FzCkpDb1ZBaUJseGNPL0kyNTVYbHIrdkxldkl6dE9zZzFEaU9mNDVYZ2prVFQwaktBUWJBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
							"organizational_unit_identifier": "client"
						},
						"enable": true,
						"orderer_ou_identifier": {
							"certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUxZYk1sbGtsaXc4b21FREYvek1ZM3N3Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEE1TWpneE56RXdNREJhRncweU9UQTUKTWpVeE56RXdNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVIrY2ZaNHJqc2w2d3BjQWlZNzA4cFJWdlNuYytWNHBrN1Z3UW1EMVZqUwowOXErNUR3dWpma3BXYnIxY0l4ZVM0amlsbHV0OUcwSmMxWlowL2ZCc3FjRW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJQldYd0RDeGtMOHB2YnFtMHhIVFJhRlh1NEpPUDZEMWRKTDNuK2NNcTJISgpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJQjVpNEtldFp6S1ArY0FHcEEwUlpjcnRWd0hISnlvOHZDdEN1L2FzCkpDb1ZBaUJseGNPL0kyNTVYbHIrdkxldkl6dE9zZzFEaU9mNDVYZ2prVFQwaktBUWJBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
							"organizational_unit_identifier": "orderer"
						},
						"peer_ou_identifier": {
							"certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUxZYk1sbGtsaXc4b21FREYvek1ZM3N3Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEE1TWpneE56RXdNREJhRncweU9UQTUKTWpVeE56RXdNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVIrY2ZaNHJqc2w2d3BjQWlZNzA4cFJWdlNuYytWNHBrN1Z3UW1EMVZqUwowOXErNUR3dWpma3BXYnIxY0l4ZVM0amlsbHV0OUcwSmMxWlowL2ZCc3FjRW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJQldYd0RDeGtMOHB2YnFtMHhIVFJhRlh1NEpPUDZEMWRKTDNuK2NNcTJISgpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJQjVpNEtldFp6S1ArY0FHcEEwUlpjcnRWd0hISnlvOHZDdEN1L2FzCkpDb1ZBaUJseGNPL0kyNTVYbHIrdkxldkl6dE9zZzFEaU9mNDVYZ2prVFQwaktBUWJBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
							"organizational_unit_identifier": "peer"
						}
					},
					"intermediate_certs": [],
					"name": "ORGX",
					"organizational_unit_identifiers": [],
					"revocation_list": [],
					"root_certs": [
						"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUxZYk1sbGtsaXc4b21FREYvek1ZM3N3Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEE1TWpneE56RXdNREJhRncweU9UQTUKTWpVeE56RXdNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVIrY2ZaNHJqc2w2d3BjQWlZNzA4cFJWdlNuYytWNHBrN1Z3UW1EMVZqUwowOXErNUR3dWpma3BXYnIxY0l4ZVM0amlsbHV0OUcwSmMxWlowL2ZCc3FjRW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJQldYd0RDeGtMOHB2YnFtMHhIVFJhRlh1NEpPUDZEMWRKTDNuK2NNcTJISgpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJQjVpNEtldFp6S1ArY0FHcEEwUlpjcnRWd0hISnlvOHZDdEN1L2FzCkpDb1ZBaUJseGNPL0kyNTVYbHIrdkxldkl6dE9zZzFEaU9mNDVYZ2prVFQwaktBUWJBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
					],
					"signing_identity": null,
            "tls_intermediate_certs": [],
            "tls_root_certs": [
						"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNaakNDQWcyZ0F3SUJBZ0lRZW9ycVBFNFRZb3VZSUV0blJoQ3B1VEFLQmdncWhrak9QUVFEQWpCK01Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWNNQm9HQTFVRQpDaE1UWVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pFUE1BMEdBMVVFQ3hNR1UwUkhVMGxVTVNJd0lBWURWUVFECkV4bDBiSE5qWVM1aFptbHdMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TURreU9ERTNNVEF3TUZvWERUSTUKTURreU5URTNNVEF3TUZvd2ZqRUxNQWtHQTFVRUJoTUNRVkl4RFRBTEJnTlZCQWdUQkVOQlFrRXhEVEFMQmdOVgpCQWNUQkVOQlFrRXhIREFhQmdOVkJBb1RFMkZtYVhBdWRISnBZbVpsWkM1bmIySXVZWEl4RHpBTkJnTlZCQXNUCkJsTkVSMU5KVkRFaU1DQUdBMVVFQXhNWmRHeHpZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pCWk1CTUcKQnlxR1NNNDlBZ0VHQ0NxR1NNNDlBd0VIQTBJQUJCMEI0OUpjQlpHcmxOaTY3dFJhVnFCYkJmUzlZN01tay9QVQpKQmhWNjJ0T3RXY05zZkhlbC9JS3U0Q1lQdnRYWkI4c3FmR1JWWUFpaDM0MENlNzN6aUtqYlRCck1BNEdBMVVkCkR3RUIvd1FFQXdJQnBqQWRCZ05WSFNVRUZqQVVCZ2dyQmdFRkJRY0RBZ1lJS3dZQkJRVUhBd0V3RHdZRFZSMFQKQVFIL0JBVXdBd0VCL3pBcEJnTlZIUTRFSWdRZzFkVm9wQnFQc3NWTTJISFQ2WmVuWXlTcEZzR0JhZm95Zk45WQowcTd2bWRzd0NnWUlLb1pJemowRUF3SURSd0F3UkFJZ1N4djNCTU5FTzBWNHZGVkpQUkJxZnY3eTU1K1UreHdHCnIweUZMMGIxdnBzQ0lCa2VZR1JUVjlaM0poNy81ZjJQbEVkNmJ1V0F2Sk9jN0dBSG5DN0ZaV00rCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
					]
				},
				"type": 0
			},
			"version": "0"
		}
	},
	"version": "0"
}
'
readonly BASE64_CRT="LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNZVENDQWdpZ0F3SUJBZ0lSQUp4M09FNnNtNWZPd2JLZFVZcjFyem93Q2dZSUtvWkl6ajBFQXdJd2V6RUwKTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFnVEJFTkJRa0V4RFRBTEJnTlZCQWNUQkVOQlFrRXhIREFhQmdOVgpCQW9URTJGbWFYQXVkSEpwWW1abFpDNW5iMkl1WVhJeER6QU5CZ05WQkFzVEJsTkVSMU5KVkRFZk1CMEdBMVVFCkF4TVdZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pBZUZ3MHhPVEV3TURReE5qSXlNREJhRncweU9URXcKTURFeE5qSXlNREJhTUhzeEN6QUpCZ05WQkFZVEFrRlNNUTB3Q3dZRFZRUUlFd1JEUVVKQk1RMHdDd1lEVlFRSApFd1JEUVVKQk1Sd3dHZ1lEVlFRS0V4TmhabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlNUTh3RFFZRFZRUUxFd1pUClJFZFRTVlF4SHpBZEJnTlZCQU1URm1OaExtRm1hWEF1ZEhKcFltWmxaQzVuYjJJdVlYSXdXVEFUQmdjcWhrak8KUFFJQkJnZ3Foa2pPUFFNQkJ3TkNBQVRmK3JsdFNvN1lWdHlma3ZQaUk5MjY1dHQ1UzlIcDhnMnE1eHpoVWNvSgpmWS9RSkpPdlRJbDJFQjNjN1FpRmR4WDJ2TUdjRmxrK0h1OWx0UE9rZkxtZW8yMHdhekFPQmdOVkhROEJBZjhFCkJBTUNBYVl3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGQndNQk1BOEdBMVVkRXdFQi93UUYKTUFNQkFmOHdLUVlEVlIwT0JDSUVJSkdPdU1ycWlFYjZ0MmEzS2NLNWRaL29Nd3A5Nnl2azFYWDM2cXE3WHkvegpNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJR2tPVCtkWHdLTEFjMVBmVG0zYW9sc2NiRFBFdWlXeEpzbEp5c2NOCmhad2tBaUJwb3A5RE9Cd3ZCWGpHR2xabHpqU3M5WjFUKzlhOXBhdGdJSG1UWVVXVG1nPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="

readonly BASE64_CRT_2="LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNaakNDQWcyZ0F3SUJBZ0lRZW9ycVBFNFRZb3VZSUV0blJoQ3B1VEFLQmdncWhrak9QUVFEQWpCK01Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWNNQm9HQTFVRQpDaE1UWVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pFUE1BMEdBMVVFQ3hNR1UwUkhVMGxVTVNJd0lBWURWUVFECkV4bDBiSE5qWVM1aFptbHdMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TURreU9ERTNNVEF3TUZvWERUSTUKTURreU5URTNNVEF3TUZvd2ZqRUxNQWtHQTFVRUJoTUNRVkl4RFRBTEJnTlZCQWdUQkVOQlFrRXhEVEFMQmdOVgpCQWNUQkVOQlFrRXhIREFhQmdOVkJBb1RFMkZtYVhBdWRISnBZbVpsWkM1bmIySXVZWEl4RHpBTkJnTlZCQXNUCkJsTkVSMU5KVkRFaU1DQUdBMVVFQXhNWmRHeHpZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pCWk1CTUcKQnlxR1NNNDlBZ0VHQ0NxR1NNNDlBd0VIQTBJQUJCMEI0OUpjQlpHcmxOaTY3dFJhVnFCYkJmUzlZN01tay9QVQpKQmhWNjJ0T3RXY05zZkhlbC9JS3U0Q1lQdnRYWkI4c3FmR1JWWUFpaDM0MENlNzN6aUtqYlRCck1BNEdBMVVkCkR3RUIvd1FFQXdJQnBqQWRCZ05WSFNVRUZqQVVCZ2dyQmdFRkJRY0RBZ1lJS3dZQkJRVUhBd0V3RHdZRFZSMFQKQVFIL0JBVXdBd0VCL3pBcEJnTlZIUTRFSWdRZzFkVm9wQnFQc3NWTTJISFQ2WmVuWXlTcEZzR0JhZm95Zk45WQowcTd2bWRzd0NnWUlLb1pJemowRUF3SURSd0F3UkFJZ1N4djNCTU5FTzBWNHZGVkpQUkJxZnY3eTU1K1UreHdHCnIweUZMMGIxdnBzQ0lCa2VZR1JUVjlaM0poNy81ZjJQbEVkNmJ1V0F2Sk9jN0dBSG5DN0ZaV00rCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"

readonly ARRAY_OF_BASE64_CRT="[\"$BASE64_CRT\",\"$BASE64_CRT_2\"]"


readonly CONSENTER='
{
"client_tls_cert": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNmVENDQWlPZ0F3SUJBZ0lRQWxwN0RrSDhLVXFCOWxUWVlYdGVyVEFLQmdncWhrak9QUVFEQWpCK01Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWNNQm9HQTFVRQpDaE1UWVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pFUE1BMEdBMVVFQ3hNR1UwUkhVMGxVTVNJd0lBWURWUVFECkV4bDBiSE5qWVM1aFptbHdMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTJNakl3TUZvWERUSTUKTVRBd01URTJNakl3TUZvd1lqRUxNQWtHQTFVRUJoTUNRVkl4RFRBTEJnTlZCQWdUQkVOQlFrRXhEVEFMQmdOVgpCQWNUQkVOQlFrRXhEekFOQmdOVkJBc1RCbE5FUjFOSlZERWtNQ0lHQTFVRUF4TWJiM0prWlhKbGNpNWhabWx3CkxuUnlhV0ptWldRdVoyOWlMbUZ5TUZrd0V3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFcmtUQ2d0L1AKcTU4KzVTUHFmOGtraFNQM1NiZ1g3MzlNMk0vTExTMXNCVTh2VUJCalNZV2VtMlhqNVVXYmN0Y3QycjlaOHM1VQpJWlJDNXpUWDVqYWZZcU9CbmpDQm16QU9CZ05WSFE4QkFmOEVCQU1DQmFBd0hRWURWUjBsQkJZd0ZBWUlLd1lCCkJRVUhBd0VHQ0NzR0FRVUZCd01DTUF3R0ExVWRFd0VCL3dRQ01BQXdLd1lEVlIwakJDUXdJb0FnUDhQSFNVTk0Kc0NDRm5sQ1VBUDczSFNLZjVENUU1UGF0ZXJOWEJXUExkY2t3THdZRFZSMFJCQ2d3Sm9JYmIzSmtaWEpsY2k1aApabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlnZ2R2Y21SbGNtVnlNQW9HQ0NxR1NNNDlCQU1DQTBnQU1FVUNJUUQ0Cnl5bGlYZDRPaHJpNFA3SG8wMGNBeXFBUXA3azZZdCtZMmwxVmJWbTM4Z0lnTTVWVHhUTEtmeWY4UlNCaTN3SWcKSmJMZVlQeHhjRkFyNzhMVGNWcVhtMTA9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
"host": "orderer1.afip.tribfed.gob.ar",
"port": 7050,
"server_tls_cert": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNmVENDQWlPZ0F3SUJBZ0lRQWxwN0RrSDhLVXFCOWxUWVlYdGVyVEFLQmdncWhrak9QUVFEQWpCK01Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWNNQm9HQTFVRQpDaE1UWVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pFUE1BMEdBMVVFQ3hNR1UwUkhVMGxVTVNJd0lBWURWUVFECkV4bDBiSE5qWVM1aFptbHdMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TVRBd05ERTJNakl3TUZvWERUSTUKTVRBd01URTJNakl3TUZvd1lqRUxNQWtHQTFVRUJoTUNRVkl4RFRBTEJnTlZCQWdUQkVOQlFrRXhEVEFMQmdOVgpCQWNUQkVOQlFrRXhEekFOQmdOVkJBc1RCbE5FUjFOSlZERWtNQ0lHQTFVRUF4TWJiM0prWlhKbGNpNWhabWx3CkxuUnlhV0ptWldRdVoyOWlMbUZ5TUZrd0V3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFcmtUQ2d0L1AKcTU4KzVTUHFmOGtraFNQM1NiZ1g3MzlNMk0vTExTMXNCVTh2VUJCalNZV2VtMlhqNVVXYmN0Y3QycjlaOHM1VQpJWlJDNXpUWDVqYWZZcU9CbmpDQm16QU9CZ05WSFE4QkFmOEVCQU1DQmFBd0hRWURWUjBsQkJZd0ZBWUlLd1lCCkJRVUhBd0VHQ0NzR0FRVUZCd01DTUF3R0ExVWRFd0VCL3dRQ01BQXdLd1lEVlIwakJDUXdJb0FnUDhQSFNVTk0Kc0NDRm5sQ1VBUDczSFNLZjVENUU1UGF0ZXJOWEJXUExkY2t3THdZRFZSMFJCQ2d3Sm9JYmIzSmtaWEpsY2k1aApabWx3TG5SeWFXSm1aV1F1WjI5aUxtRnlnZ2R2Y21SbGNtVnlNQW9HQ0NxR1NNNDlCQU1DQTBnQU1FVUNJUUQ0Cnl5bGlYZDRPaHJpNFA3SG8wMGNBeXFBUXA3azZZdCtZMmwxVmJWbTM4Z0lnTTVWVHhUTEtmeWY4UlNCaTN3SWcKSmJMZVlQeHhjRkFyNzhMVGNWcVhtMTA9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
}'

}

mocks

mkdir -p ./tmp
readonly CONFIG_JSON_FILE=$( mktemp ./tmp/$$.XXXXXX.original.config.json )
echo $CONFIG_JSON > "$CONFIG_JSON_FILE"

readonly ORGX_CJSON=$( echo $ORGX_JSON | jq -ec '.')

if [[ -z $ORGX_CJSON ]]; then
   echo_red "ERROR: mock ORGX_CJSON is empty"
   exit
fi

set -x
./ch.config.tool.sh read        -o "$CONFIG_JSON_FILE"  
./ch.config.tool.sh read        -o "$CONFIG_JSON_FILE" -g orderer 
./ch.config.tool.sh read        -o "$CONFIG_JSON_FILE" -g application -m AFIP -k fabric_node_ous
./ch.config.tool.sh read        -o "$CONFIG_JSON_FILE" -g application -m AFIP -k organizational_unit_identifiers
./ch.config.tool.sh decode      -o "$CONFIG_JSON_FILE" -g application -m AFIP -k organizational_unit_identifier

./ch.config.tool.sh add         -o "$CONFIG_JSON_FILE" -g application -m ORGX -k org -v "$ORGX_CJSON"

rm -f "/tmp/orgx.json"
cat <<< "$ORGX_CJSON" > "/tmp/orgx.json"
./ch.config.tool.sh add         -o "$CONFIG_JSON_FILE" -g application -m ORGX -k org -v "/tmp/orgx.json"

./ch.config.tool.sh set_anchor  -o "$CONFIG_JSON_FILE"                -m AFIP -n peer0.x -p 7051
./ch.config.tool.sh replace_crt -o "$CONFIG_JSON_FILE"                -m AFIP -v "$BASE64_CRT" -V "$BASE64_CRT_2"
./ch.config.tool.sh add         -o "$CONFIG_JSON_FILE"                -m AFIP -k common_ica_certs -v "$BASE64_CRT"

rm -f "/tmp/eapp.tx.pb"
./ch.config.tool.sh add         -o "$CONFIG_JSON_FILE"                -m AFIP -k admins -v "$BASE64_CRT" -u "/tmp/eapp.tx.pb"
check_file "/tmp/eapp.tx.pb"

rm -f "/tmp/kv_file"
cat <<< "
absolute_max_bytes=5242880
max_message_count=9999
preferred_max_bytes=4194304
tick_interval=\"99ms\"
" > "/tmp/kv_file"
./ch.config.tool.sh set_values -o "$CONFIG_JSON_FILE" -g Orderer -f "/tmp/kv_file"

./ch.config.tool.sh set_value  -o "$CONFIG_JSON_FILE" -k preferred_max_bytes -v 100

./ch.config.tool.sh add -o "$CONFIG_JSON_FILE" -k consenter -v "$CONSENTER"

readonly b641='"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNaakNDQWcyZ0F3SUJBZ0lRZW9ycVBFNFRZb3VZSUV0blJoQ3B1VEFLQmdncWhrak9QUVFEQWpCK01Rc3cKQ1FZRFZRUUdFd0pCVWpFTk1Bc0dBMVVFQ0JNRVEwRkNRVEVOTUFzR0ExVUVCeE1FUTBGQ1FURWNNQm9HQTFVRQpDaE1UWVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pFUE1BMEdBMVVFQ3hNR1UwUkhVMGxVTVNJd0lBWURWUVFECkV4bDBiSE5qWVM1aFptbHdMblJ5YVdKbVpXUXVaMjlpTG1GeU1CNFhEVEU1TURreU9ERTNNVEF3TUZvWERUSTUKTURreU5URTNNVEF3TUZvd2ZqRUxNQWtHQTFVRUJoTUNRVkl4RFRBTEJnTlZCQWdUQkVOQlFrRXhEVEFMQmdOVgpCQWNUQkVOQlFrRXhIREFhQmdOVkJBb1RFMkZtYVhBdWRISnBZbVpsWkM1bmIySXVZWEl4RHpBTkJnTlZCQXNUCkJsTkVSMU5KVkRFaU1DQUdBMVVFQXhNWmRHeHpZMkV1WVdacGNDNTBjbWxpWm1Wa0xtZHZZaTVoY2pCWk1CTUcKQnlxR1NNNDlBZ0VHQ0NxR1NNNDlBd0VIQTBJQUJCMEI0OUpjQlpHcmxOaTY3dFJhVnFCYkJmUzlZN01tay9QVQpKQmhWNjJ0T3RXY05zZkhlbC9JS3U0Q1lQdnRYWkI4c3FmR1JWWUFpaDM0MENlNzN6aUtqYlRCck1BNEdBMVVkCkR3RUIvd1FFQXdJQnBqQWRCZ05WSFNVRUZqQVVCZ2dyQmdFRkJRY0RBZ1lJS3dZQkJRVUhBd0V3RHdZRFZSMFQKQVFIL0JBVXdBd0VCL3pBcEJnTlZIUTRFSWdRZzFkVm9wQnFQc3NWTTJISFQ2WmVuWXlTcEZzR0JhZm95Zk45WQowcTd2bWRzd0NnWUlLb1pJemowRUF3SURSd0F3UkFJZ1N4djNCTU5FTzBWNHZGVkpQUkJxZnY3eTU1K1UreHdHCnIweUZMMGIxdnBzQ0lCa2VZR1JUVjlaM0poNy81ZjJQbEVkNmJ1V0F2Sk9jN0dBSG5DN0ZaV00rCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"'
readonly b642='"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUIyekNDQVlLZ0F3SUJBZ0lCQVRBS0JnZ3Foa2pPUFFRREFqQXpNUXN3Q1FZRFZRUUdFd0pCVWpFTk1Bc0cKQTFVRUNnd0VRVVpKVURFVk1CTUdBMVVFQXd3TVFVWkpVQ0JTYjI5MElFTkJNQjRYRFRFNU1USXhOakV5TkRFMApPRm9YRFRJNU1USXhNekV5TkRFME9Gb3dWREVMTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFvTUJFRkdTVkF4Ck5qQTBCZ05WQkFNTUxXMXpjR2xqWVM1aWJHOWphMk5vWVdsdUxYUnlhV0oxZEdGeWFXRXVhRzl0Ynk1aFptbHcKTG1kdllpNWhjakJaTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEEwSUFCRVF0aEJrMUFic2sycXYrS3h6MgpmbEVSR1FQa0FIaXhlRHFPOUhmdS9DQmloYVBTRkhlUFNIcFk3WmNudkJtOG5yR01uOTN3cFZQbnpuUlZQR09zCnA4ZWpaakJrTUIwR0ExVWREZ1FXQkJRTE94RWU0bi90Wk1BWVZ0Vm52bmQ4R2JRQWdqQWZCZ05WSFNNRUdEQVcKZ0JSZmZEVEJLT0g2NzdDRWZwVXZ2U2tTYUJtTVp6QVNCZ05WSFJNQkFmOEVDREFHQVFIL0FnRUFNQTRHQTFVZApEd0VCL3dRRUF3SUJoakFLQmdncWhrak9QUVFEQWdOSEFEQkVBaUErRXMxMGljeWZQRlNzRFBnc2VPNmR2RUJCCmJmeFpxaTFNUktabjR4WldCd0lnR21Oa3lKcEQ4YjdxdUV2eUxnVHFROUd4dDd6Mnk4OTA4bFBCTzBlZkNTbz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="'

./ch.config.tool.sh set_value -o "$CONFIG_JSON_FILE" -m AFIP -k tls_root_certs -v "[$b641]"

readonly organizational_unit_identifier='"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUIyekNDQVlLZ0F3SUJBZ0lCQVRBS0JnZ3Foa2pPUFFRREFqQXpNUXN3Q1FZRFZRUUdFd0pCVWpFTk1Bc0cKQTFVRUNnd0VRVVpKVURFVk1CTUdBMVVFQXd3TVFVWkpVQ0JTYjI5MElFTkJNQjRYRFRFNU1USXhOakV5TkRFMApPRm9YRFRJNU1USXhNekV5TkRFME9Gb3dWREVMTUFrR0ExVUVCaE1DUVZJeERUQUxCZ05WQkFvTUJFRkdTVkF4Ck5qQTBCZ05WQkFNTUxXMXpjR2xqWVM1aWJHOWphMk5vWVdsdUxYUnlhV0oxZEdGeWFXRXVhRzl0Ynk1aFptbHcKTG1kdllpNWhjakJaTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEEwSUFCRVF0aEJrMUFic2sycXYrS3h6MgpmbEVSR1FQa0FIaXhlRHFPOUhmdS9DQmloYVBTRkhlUFNIcFk3WmNudkJtOG5yR01uOTN3cFZQbnpuUlZQR09zCnA4ZWpaakJrTUIwR0ExVWREZ1FXQkJRTE94RWU0bi90Wk1BWVZ0Vm52bmQ4R2JRQWdqQWZCZ05WSFNNRUdEQVcKZ0JSZmZEVEJLT0g2NzdDRWZwVXZ2U2tTYUJtTVp6QVNCZ05WSFJNQkFmOEVDREFHQVFIL0FnRUFNQTRHQTFVZApEd0VCL3dRRUF3SUJoakFLQmdncWhrak9QUVFEQWdOSEFEQkVBaUErRXMxMGljeWZQRlNzRFBnc2VPNmR2RUJCCmJmeFpxaTFNUktabjR4WldCd0lnR21Oa3lKcEQ4YjdxdUV2eUxnVHFROUd4dDd6Mnk4OTA4bFBCTzBlZkNTbz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="'
./ch.config.tool.sh set_value -o "$CONFIG_JSON_FILE" -m AFIP -k organizational_unit_identifier -v "$b642"

readonly organizational_unit_identifiers="[
{	\"certificate\": $b641, \"organizational_unit_identifier\": \"MSP-TRIBUTARIA\" },
{	\"certificate\": $b642, \"organizational_unit_identifier\": \"MSP-TRIBUTARIA\" }
]"

./ch.config.tool.sh set_value -o "$CONFIG_JSON_FILE" -m AFIP -k organizational_unit_identifiers -v "$organizational_unit_identifiers"

set +x

echo_success
