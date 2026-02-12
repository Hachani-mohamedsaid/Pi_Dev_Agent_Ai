import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/usecases/submit_meeting_decision_usecase.dart';
import '../../data/datasources/meeting_decision_remote_data_source.dart';

class MeetingDecisionController extends ChangeNotifier {
  final SubmitMeetingDecisionUseCase submitMeetingDecisionUseCase;

  // Form state
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedDecision = 'accept';
  int durationMinutes = 30;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  MeetingDecisionController({required this.submitMeetingDecisionUseCase});

  void setDate(DateTime date) {
    selectedDate = date;
    errorMessage = null;
    if (kDebugMode) {
      debugPrint('Controller.setDate called — date: $date, hash: ${hashCode}');
    }
    notifyListeners();
  }

  void setTime(TimeOfDay time) {
    selectedTime = time;
    errorMessage = null;
    if (kDebugMode) {
      debugPrint('Controller.setTime called — time: $time, hash: ${hashCode}');
    }
    notifyListeners();
  }

  void setDecision(String decision) {
    selectedDecision = decision;
    errorMessage = null;
    if (kDebugMode) {
      debugPrint(
        'Controller.setDecision called — decision: $decision, hash: ${hashCode}',
      );
    }
    notifyListeners();
  }

  void setDuration(int duration) {
    if (duration > 0) {
      durationMinutes = duration;
      errorMessage = null;
      if (kDebugMode) {
        debugPrint(
          'Controller.setDuration called — duration: $duration, hash: ${hashCode}',
        );
      }
      notifyListeners();
    }
  }

  String? validateForm() {
    if (selectedDate == null) {
      return 'Please select a meeting date';
    }
    if (selectedTime == null) {
      return 'Please select a meeting time';
    }
    if (durationMinutes <= 0) {
      return 'Duration must be greater than 0';
    }
    return null;
  }

  Future<void> submitDecision(String token) async {
    print("🔥 CONTROLLER SUBMIT STARTED");
    final validationError = validateForm();
    if (validationError != null) {
      errorMessage = validationError;
      if (kDebugMode) {
        debugPrint('❌ VALIDATION ERROR: $validationError');
      }
      notifyListeners();
      return;
    }

    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎯 MEETING DECISION - FORM SUBMISSION STARTED');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📅 Selected Date: $selectedDate');
      debugPrint('⏰ Selected Time: $selectedTime');
      debugPrint('✅ Decision: $selectedDecision');
      debugPrint('⏱️  Duration: $durationMinutes minutes');
      debugPrint('═══════════════════════════════════════════════════════');
    }

    isLoading = true;
    errorMessage = null;
    successMessage = null;
    if (kDebugMode)
      debugPrint(
        'Controller.submitDecision — starting notifyListeners for loading state',
      );
    notifyListeners();

    try {
      final meetingDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      if (kDebugMode) {
        debugPrint('⏱️  Combined DateTime: $meetingDateTime');
        debugPrint(
          '🔐 Token provided: ${token.isNotEmpty ? 'Yes' : 'No (EMPTY!)'}',
        );
      }

      // Debug payload
      print('📦 Payload:');
      print({
        "date": selectedDate,
        "time": selectedTime,
        "decision": selectedDecision,
        "duration": durationMinutes,
      });

      await submitMeetingDecisionUseCase(
        meetingDate: selectedDate!,
        meetingTime: meetingDateTime,
        decision: selectedDecision,
        durationMinutes: durationMinutes,
        token: token,
      );

      successMessage = 'Meeting decision submitted successfully!';
      if (kDebugMode) {
        debugPrint('✅ CONTROLLER: Success message set');
      }
      resetForm();
    } on UnauthorizedException catch (e) {
      errorMessage = 'Authentication error: ${e.message}';
      if (kDebugMode) {
        debugPrint('❌ CONTROLLER: UnauthorizedException - ${e.message}');
      }
    } on BadRequestException catch (e) {
      errorMessage = 'Invalid input: ${e.message}';
      if (kDebugMode) {
        debugPrint('❌ CONTROLLER: BadRequestException - ${e.message}');
      }
    } on ServerException catch (e) {
      errorMessage = 'Server error: ${e.message}';
      if (kDebugMode) {
        debugPrint('❌ CONTROLLER: ServerException - ${e.message}');
      }
    } on NetworkException catch (e) {
      errorMessage = 'Network error: ${e.message}';
      if (kDebugMode) {
        debugPrint('❌ CONTROLLER: NetworkException - ${e.message}');
      }
    } catch (e) {
      errorMessage = 'An unexpected error occurred: ${e.toString()}';
      if (kDebugMode) {
        debugPrint(
          '❌ CONTROLLER: Unexpected Exception - ${e.runtimeType}: ${e.toString()}',
        );
      }
    } finally {
      isLoading = false;
      if (kDebugMode)
        debugPrint(
          'Controller.submitDecision — final notifyListeners (loading false)',
        );
      notifyListeners();
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🏁 MEETING DECISION - SUBMISSION COMPLETE');
        debugPrint('═══════════════════════════════════════════════════════');
      }
    }
  }

  void resetForm() {
    selectedDate = null;
    selectedTime = null;
    selectedDecision = 'accept';
    durationMinutes = 30;
    errorMessage = null;
    if (kDebugMode)
      debugPrint('Controller.resetForm called — notifying listeners');
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    if (kDebugMode)
      debugPrint('Controller.clearMessages called — notifying listeners');
    notifyListeners();
  }
}
