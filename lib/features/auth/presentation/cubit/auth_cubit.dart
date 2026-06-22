import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/imgbb_service.dart';
import '../../data/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final ImgBBService _imgBBService;

  AuthCubit({
    required AuthRepository authRepository,
    required ImgBBService imgBBService,
  })  : _authRepository = authRepository,
        _imgBBService = imgBBService,
        super(AuthInitial()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      _authRepository.user.listen((firebaseUser) async {
        if (firebaseUser != null) {
          try {
            final userModel = await _authRepository.getUserProfile(firebaseUser.uid);
            emit(AuthAuthenticated(userModel));
          } catch (e) {
            emit(AuthUnauthenticated());
          }
        } else {
          emit(AuthUnauthenticated());
        }
      });
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signUpWithEmail(String fullName, String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
    } catch (e) {
      emit(AuthError(e.toString()));
      if (state is! AuthAuthenticated) {
        emit(AuthUnauthenticated());
      }
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateProfileInfo(String fullName, String phoneNumber) async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      emit(AuthLoading());
      try {
        final updatedUser = currentUser.copyWith(fullName: fullName, phoneNumber: phoneNumber);
        await _authRepository.updateUserProfile(updatedUser);
        emit(AuthAuthenticated(updatedUser));
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(AuthAuthenticated(currentUser));
      }
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      emit(AuthLoading());
      try {
        await _authRepository.changePassword(currentPassword, newPassword);
        emit(AuthAuthenticated(currentUser));
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(AuthAuthenticated(currentUser));
      }
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      emit(AuthLoading());
      try {
        final avatarUrl = await _imgBBService.uploadAvatar(imageFile);
        if (avatarUrl != null) {
          final updatedUser = currentUser.copyWith(avatarUrl: avatarUrl);
          await _authRepository.updateUserProfile(updatedUser);
          emit(AuthAuthenticated(updatedUser));
        } else {
          emit(const AuthError("Failed to upload avatar"));
          emit(AuthAuthenticated(currentUser));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(AuthAuthenticated(currentUser));
      }
    }
  }

  Future<void> addShippingAddress(ShippingAddress address) async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      emit(AuthLoading());
      try {
        final updatedAddresses = List<ShippingAddress>.from(currentUser.shippingAddresses)..add(address);
        final updatedUser = currentUser.copyWith(shippingAddresses: updatedAddresses);
        await _authRepository.updateUserProfile(updatedUser);
        emit(AuthAuthenticated(updatedUser));
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(AuthAuthenticated(currentUser));
      }
    }
  }

  Future<void> updateShippingAddress(ShippingAddress updatedAddress) async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      emit(AuthLoading());
      try {
        final updatedAddresses = currentUser.shippingAddresses.map((addr) {
          return addr.id == updatedAddress.id ? updatedAddress : addr;
        }).toList();
        
        final updatedUser = currentUser.copyWith(shippingAddresses: updatedAddresses);
        await _authRepository.updateUserProfile(updatedUser);
        emit(AuthAuthenticated(updatedUser));
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(AuthAuthenticated(currentUser));
      }
    }
  }

  Future<void> removeShippingAddress(String addressId) async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      emit(AuthLoading());
      try {
        final updatedAddresses = currentUser.shippingAddresses.where((addr) => addr.id != addressId).toList();
        final updatedUser = currentUser.copyWith(shippingAddresses: updatedAddresses);
        await _authRepository.updateUserProfile(updatedUser);
        emit(AuthAuthenticated(updatedUser));
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(AuthAuthenticated(currentUser));
      }
    }
  }
}
