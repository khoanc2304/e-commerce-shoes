import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/models/order_model.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _orderRepository;

  OrderCubit({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(OrderInitial());

  Stream<List<OrderModel>> getOrdersStream(String userId) {
    return _orderRepository.getOrdersStream(userId);
  }
}
