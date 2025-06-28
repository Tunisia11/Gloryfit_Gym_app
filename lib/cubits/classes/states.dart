import 'package:equatable/equatable.dart';
import 'package:gloryfit_version_3/models/classes/class_model.dart';

abstract class ClassState extends Equatable {
  const ClassState();

  @override
  List<Object> get props => [];
}

class ClassInitial extends ClassState {}

class ClassLoading extends ClassState {}

class ClassesLoaded extends ClassState {
  final List<Class> classes;

  const ClassesLoaded(this.classes);

  @override
  List<Object> get props => [classes];
}

class ClassOperationSuccess extends ClassState {
  final String message;
  const ClassOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ClassError extends ClassState {
  final String message;

  const ClassError(this.message);

  @override
  List<Object> get props => [message];
}
