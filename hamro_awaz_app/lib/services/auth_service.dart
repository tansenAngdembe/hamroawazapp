import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/debug_helper.dart';
import '../models/user.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // Get access token from storage
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Get refresh token from storage
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Save tokens to storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  // Clear tokens from storage
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  // Save user data to storage
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Get user data from storage
  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return User.fromJson(jsonDecode(userJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Sign up user
  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.signup}');
      final body = jsonEncode({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
      });
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      DebugHelper.logApiCall('POST', url.toString(), headers, {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': '[HIDDEN]',
        'confirmPassword': '[HIDDEN]',
      });
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        DebugHelper.logError('Signup JSON decode error', e);
        return {
          'success': false,
          'message': 'Invalid JSON response from server: ${response.body}',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message']?.toString() ?? 'Account created successfully',
          'data': responseData,
        };
      } else {
        String errorMessage = 'Failed to create account';
        
        if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'].toString();
        } else if (response.statusCode == 400) {
          errorMessage = 'Invalid request. Please check your input.';
        } else if (response.statusCode == 409) {
          errorMessage = 'Email or phone number already exists.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Server error. Please try again later.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } on TimeoutException catch (e) {
      print('Signup timeout error: $e');
      return {
        'success': false,
        'message': 'Request timeout. Please try again.',
      };
    } on http.ClientException catch (e) {
      print('Signup HTTP Client error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    } catch (e) {
      print('Signup error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');
      final body = jsonEncode({'email': email, 'password': password});
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      DebugHelper.logApiCall('POST', url.toString(), headers, body);
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      DebugHelper.logApiResponse(response.statusCode, response.body);

      // Handle empty response
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        DebugHelper.logError('JSON decode error in login', e);
        return {
          'success': false,
          'message': 'Invalid JSON response from server: ${response.body}',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if the response indicates success even with 200 status
        final httpStatus = responseData['httpStatus']?.toString();
        final code = responseData['code'];
        
        // Your backend might return 200 but with error status
        if (httpStatus == 'BAD_REQUEST' || httpStatus == 'UNAUTHORIZED' || 
            code == 422 || code == 401 || code == 400) {
          // This is actually an error response
          String errorMessage = responseData['message']?.toString() ?? 'Login failed';
          
          return {
            'success': false,
            'message': errorMessage,
            'statusCode': code ?? response.statusCode,
            'httpStatus': httpStatus,
          };
        }
        
        // Handle successful login response
        String? accessToken;
        String? refreshToken;
        User? user;

        // Check if response has the expected structure with 'data' field
        if (responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          // Extract tokens from the data field
          accessToken = data['accessToken']?.toString();
          refreshToken = data['refreshToken']?.toString();
        } else {
          // Fallback to direct fields
          accessToken = responseData['accessToken']?.toString() ?? 
                       responseData['token']?.toString() ??
                       responseData['access_token']?.toString();
          
          refreshToken = responseData['refreshToken']?.toString() ??
                        responseData['refresh_token']?.toString();
        }

        DebugHelper.log('Login tokens extracted', {
          'hasAccessToken': accessToken != null,
          'hasRefreshToken': refreshToken != null,
          'accessToken': accessToken?.substring(0, 20) ?? 'null',
          'refreshToken': refreshToken?.substring(0, 20) ?? 'null',
        });

        // Save tokens if available
        if (accessToken != null && refreshToken != null) {
          await _saveTokens(accessToken, refreshToken);
          DebugHelper.log('Tokens saved successfully');
        } else if (accessToken != null) {
          // Some APIs only return access token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_accessTokenKey, accessToken);
          DebugHelper.log('Access token saved (no refresh token)');
        } else {
          DebugHelper.log('No tokens found in response');
          return {
            'success': false,
            'message': 'No authentication tokens received from server',
          };
        }

        // Try to extract user data from login response
        Map<String, dynamic>? userData;
        
        // Check different possible locations for user data
        if (responseData['data'] != null && responseData['data']['user'] != null) {
          userData = responseData['data']['user'] as Map<String, dynamic>;
        } else if (responseData['user'] != null) {
          userData = responseData['user'] as Map<String, dynamic>;
        }
        
        if (userData != null) {
          try {
            user = User.fromJson(userData);
            await _saveUser(user);
            DebugHelper.log('User data extracted from login response', user.toJson());
          } catch (e) {
            DebugHelper.logError('Error parsing user data from login response', e);
          }
        }

        // If no user data in login response, try to fetch profile
        if (user == null && accessToken != null) {
          DebugHelper.log('No user data in login response, fetching profile');
          final userResult = await getProfile();
          if (userResult['success'] == true && userResult['user'] != null) {
            user = userResult['user'] as User;
            DebugHelper.log('User profile fetched successfully');
          } else {
            DebugHelper.log('Failed to fetch user profile, creating basic user from token', userResult);
            // Create a basic user from the token if profile fetch fails
            user = _createUserFromToken(accessToken);
            if (user != null) {
              await _saveUser(user);
              DebugHelper.log('Basic user created from token', user.toJson());
            }
          }
        }

        // Extract message from response
        String successMessage = 'Login successful';
        if (responseData['message'] != null) {
          successMessage = responseData['message'].toString();
        }

        return {
          'success': true,
          'message': successMessage,
          'user': user,
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'httpStatus': responseData['httpStatus'],
          'code': responseData['code'],
        };
      } else {
        // Handle HTTP error status codes (400, 401, 422, 500, etc.)
        String errorMessage = 'Login failed';
        
        if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'].toString();
        } else if (response.statusCode == 401) {
          errorMessage = 'Invalid email or password';
        } else if (response.statusCode == 400) {
          errorMessage = 'Invalid request. Please check your input.';
        } else if (response.statusCode == 422) {
          errorMessage = responseData['message']?.toString() ?? 'Invalid credentials or account does not exist';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Server error. Please try again later.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
          'httpStatus': responseData['httpStatus'],
          'code': responseData['code'],
        };
      }
    } on http.ClientException catch (e) {
      DebugHelper.logError('HTTP Client error in login', e);
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    } on FormatException catch (e) {
      DebugHelper.logError('Format error in login', e);
      return {
        'success': false,
        'message': 'Invalid server response format.',
      };
    } catch (e) {
      DebugHelper.logError('Login error', e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Check authentication status
  Future<Map<String, dynamic>> checkAuth() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'authenticated': false,
          'message': 'No access token found',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.checkAuth}');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      
      DebugHelper.logApiCall('GET', url.toString(), headers, null);
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {
            'success': true,
            'authenticated': true,
          };
        }

        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          // If JSON parsing fails but status is 200, assume authenticated
          return {
            'success': true,
            'authenticated': true,
          };
        }
        
        // Check your backend's response structure
        final httpStatus = responseData['httpStatus']?.toString();
        final code = responseData['code'];
        final message = responseData['message']?.toString();
        
        // Check if the response indicates authentication success
        if (httpStatus == 'OK' && code == 200 && message == 'AUTHENTICATED') {
          // Update tokens if provided
          if (responseData['data'] != null) {
            final data = responseData['data'] as Map<String, dynamic>;
            final newAccessToken = data['accessToken']?.toString();
            final newRefreshToken = data['refreshToken']?.toString();
            if (newAccessToken != null && newRefreshToken != null) {
              await _saveTokens(newAccessToken, newRefreshToken);
            }
          }

          return {
            'success': true,
            'authenticated': true,
            'data': responseData,
            'message': message,
          };
        } else {
          // Authentication failed according to your backend
          await _clearTokens();
          return {
            'success': false,
            'authenticated': false,
            'message': message ?? 'Authentication failed',
          };
        }
      } else if (response.statusCode == 401) {
        await _clearTokens();
        return {
          'success': false,
          'authenticated': false,
          'message': 'Authentication expired',
        };
      } else {
        // Try to parse error message from response
        String errorMessage = 'Authentication check failed (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (e) {
          // Use default error message
        }
        
        return {
          'success': false,
          'authenticated': false,
          'message': errorMessage,
        };
      }
    } on TimeoutException catch (e) {
      print('CheckAuth timeout error: $e');
      return {
        'success': false,
        'authenticated': false,
        'message': 'Request timeout',
      };
    } on http.ClientException catch (e) {
      print('CheckAuth HTTP Client error: $e');
      return {
        'success': false,
        'authenticated': false,
        'message': 'Connection error',
      };
    } catch (e) {
      print('CheckAuth error: $e');
      return {
        'success': false,
        'authenticated': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}');
      
      DebugHelper.logApiCall('POST', url.toString(), {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${accessToken.substring(0, 20)}...',
      }, null);
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'Empty profile response from server',
          };
        }

        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          DebugHelper.logError('Profile JSON decode error', e);
          return {
            'success': false,
            'message': 'Invalid JSON response from server',
          };
        }
        
        // Handle your backend's response structure
        Map<String, dynamic>? userData;
        
        // Check if response has the expected structure with 'data' field
        if (responseData['data'] != null) {
          userData = responseData['data'] as Map<String, dynamic>?;
        } else if (responseData['user'] != null) {
          userData = responseData['user'] as Map<String, dynamic>?;
        } else {
          // Sometimes the response itself is the user data
          userData = responseData;
        }
        
        if (userData != null) {
          try {
            // Parse user data with flexible field mapping
            final user = User(
              id: userData['id']?.toString() ?? 
                     userData['userId']?.toString() ?? 
                     userData['_id']?.toString() ?? '0',
              name: userData['fullName']?.toString() ?? 
                    userData['name']?.toString() ?? 
                    userData['username']?.toString() ?? '',
              email: userData['email']?.toString() ?? '',
              phone: userData['phoneNumber']?.toString() ?? 
                     userData['phone']?.toString() ??
                     userData['mobile']?.toString(),
              role: _parseUserRole(userData['role']?.toString()),
              profileImageUrl: userData['profileImageUrl']?.toString() ?? 
                              userData['avatar']?.toString() ??
                              userData['profileImage']?.toString(),
            );

            await _saveUser(user);

            return {
              'success': true,
              'user': user,
              'message': responseData['message']?.toString() ?? 'Profile fetched successfully',
              'httpStatus': responseData['httpStatus'],
              'code': responseData['code'],
            };
          } catch (e) {
            DebugHelper.logError('Error parsing user data', e);
            return {
              'success': false,
              'message': 'Error parsing user data: ${e.toString()}',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'No user data found in response',
            'responseData': responseData,
          };
        }
      } else if (response.statusCode == 401) {
        await _clearTokens();
        return {
          'success': false,
          'message': 'Authentication expired. Please login again.',
        };
      } else {
        // Try to parse error message from response
        String errorMessage = 'Failed to fetch profile (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (e) {
          // Use default error message
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on TimeoutException catch (e) {
      DebugHelper.logError('Profile timeout error', e);
      return {
        'success': false,
        'message': 'Request timeout. Please try again.',
      };
    } on http.ClientException catch (e) {
      DebugHelper.logError('Profile HTTP Client error', e);
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    } catch (e) {
      DebugHelper.logError('Profile error', e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Helper method to parse user role
  UserRole _parseUserRole(String? roleString) {
    if (roleString == null) return UserRole.citizen;
    
    switch (roleString.toLowerCase()) {
      case 'admin':
      case 'administrator':
      case 'role_admin':
        return UserRole.admin;
      case 'citizen':
      case 'user':
      case 'role_user':
      default:
        return UserRole.citizen;
    }
  }

  // Helper method to extract email from JWT token (basic decode)
  String? _extractEmailFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode the payload (second part)
      String payload = parts[1];
      
      // Add padding if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      
      final decoded = utf8.decode(base64Decode(payload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
      
      return payloadMap['sub']?.toString(); // 'sub' usually contains the email/username
    } catch (e) {
      DebugHelper.logError('Error extracting email from token', e);
      return null;
    }
  }

  // Create a basic user from token if profile fetch fails
  User? _createUserFromToken(String accessToken) {
    final email = _extractEmailFromToken(accessToken);
    if (email == null) return null;
    
    return User(
      id: '0', // Temporary ID
      name: email.split('@')[0], // Use email prefix as name
      email: email,
      role: UserRole.citizen,
    );
  }

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final accessToken = await getAccessToken();
      
      if (accessToken != null) {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}');
        
        DebugHelper.logApiCall('POST', url.toString(), {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.substring(0, 20)}...',
        }, null);
        
        try {
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          ).timeout(const Duration(seconds: 10));

          DebugHelper.logApiResponse(response.statusCode, response.body);
        } catch (e) {
          DebugHelper.logError('Logout API call failed', e);
          // Continue with local logout even if API call fails
        }
      }

      await _clearTokens();

      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      DebugHelper.logError('Logout error', e);
      // Clear tokens even if API call fails
      await _clearTokens();
      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    }
  }

  // Verify account OTP after signup
  Future<Map<String, dynamic>> verifyAccountOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyAccountOtp}');
      final body = jsonEncode({
        'email': email.trim(),
        'otp': otp.trim(),
      });
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      DebugHelper.logApiCall('POST', url.toString(), headers, {
        'email': email.trim(),
        'otp': '[HIDDEN]',
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      DebugHelper.logApiResponse(response.statusCode, response.body);

      if (response.body.isEmpty) {
        return {
          'success': response.statusCode == 200 || response.statusCode == 201,
          'message': response.statusCode == 200 || response.statusCode == 201
              ? 'OTP verified successfully'
              : 'Empty response from server',
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        DebugHelper.logError('Verify OTP JSON decode error', e);
        return {
          'success': false,
          'message': 'Invalid JSON response from server',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message']?.toString() ?? 'OTP verified successfully',
          'data': responseData,
        };
      }

      return {
        'success': false,
        'message': responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            'OTP verification failed',
        'statusCode': response.statusCode,
      };
    } on TimeoutException catch (e) {
      DebugHelper.logError('Verify OTP timeout', e);
      return {
        'success': false,
        'message': 'Request timeout. Please try again.',
      };
    } on http.ClientException catch (e) {
      DebugHelper.logError('Verify OTP client error', e);
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    } catch (e) {
      DebugHelper.logError('Verify OTP error', e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Reset password (if still needed)
  Future<bool> resetPassword(String email) async {
    // Implement if your API supports this
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
