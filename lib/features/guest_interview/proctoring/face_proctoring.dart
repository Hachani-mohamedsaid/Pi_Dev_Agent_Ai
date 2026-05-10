export 'face_proctoring_types.dart';
import 'face_proctoring_types.dart';
import 'face_proctoring_io.dart' if (dart.library.html) 'face_proctoring_web.dart'
    as face_impl;

FaceProctoringBinding createFaceProctoringBinding() =>
    face_impl.createFaceProctoringBinding();
