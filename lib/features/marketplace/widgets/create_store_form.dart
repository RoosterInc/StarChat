import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/design_tokens.dart';
import '../controllers/seller_dashboard_controller.dart';

/// Form for creating a new marketplace store
class CreateStoreForm extends StatefulWidget {
  final SellerDashboardController controller;

  const CreateStoreForm({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<CreateStoreForm> createState() => _CreateStoreFormState();
}

class _CreateStoreFormState extends State<CreateStoreForm> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Name
          _buildFormField(
            context,
            label: 'Store Name',
            hint: 'Enter your store name',
            controller: _storeNameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Store name is required';
              }
              if (value.trim().length < 3) {
                return 'Store name must be at least 3 characters';
              }
              return null;
            },
            required: true,
          ),
          
          SizedBox(height: DesignTokens.lg(context).height),
          
          // Store Description
          _buildFormField(
            context,
            label: 'Store Description',
            hint: 'Describe what your store sells',
            controller: _storeDescriptionController,
            maxLines: 3,
            validator: (value) {
              if (value != null && value.length > 1000) {
                return 'Description must be less than 1000 characters';
              }
              return null;
            },
          ),
          
          SizedBox(height: DesignTokens.lg(context).height),
          
          // Business Email
          _buildFormField(
            context,
            label: 'Business Email',
            hint: 'your.business@email.com',
            controller: _businessEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Business email is required';
              }
              if (!GetUtils.isEmail(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            required: true,
          ),
          
          SizedBox(height: DesignTokens.lg(context).height),
          
          // Business Phone
          _buildFormField(
            context,
            label: 'Business Phone',
            hint: '+1 (555) 123-4567',
            controller: _businessPhoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          
          SizedBox(height: DesignTokens.lg(context).height),
          
          // Business Address
          _buildFormField(
            context,
            label: 'Business Address',
            hint: 'Enter your business address',
            controller: _businessAddressController,
            maxLines: 2,
            validator: (value) {
              if (value != null && value.length > 500) {
                return 'Address must be less than 500 characters';
              }
              return null;
            },
          ),
          
          SizedBox(height: DesignTokens.xl(context).height),
          
          // Terms and conditions
          Container(
            padding: DesignTokens.md(context).all,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              border: Border.all(
                color: context.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: DesignTokens.iconSm(context),
                      color: context.colorScheme.primary,
                    ),
                    SizedBox(width: DesignTokens.sm(context).width),
                    Text(
                      'Important Information',
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: DesignTokens.sm(context).height),
                
                Text(
                  '• Your store will be reviewed before activation\n'
                  '• You agree to StarChat\'s seller terms and conditions\n'
                  '• Platform commission applies to all sales\n'
                  '• You are responsible for product quality and customer service',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: DesignTokens.xl(context).height),
          
          // Create Store Button
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.controller.isCreatingStore ? null : _createStore,
              style: ElevatedButton.styleFrom(
                padding: DesignTokens.lg(context).symmetric(vertical: true),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
                ),
              ),
              child: widget.controller.isCreatingStore
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: DesignTokens.sm(context).width),
                        const Text('Creating Store...'),
                      ],
                    )
                  : const Text('Create Store'),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFormField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required) ...[
              SizedBox(width: DesignTokens.xs(context).width),
              Text(
                '*',
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        
        SizedBox(height: DesignTokens.sm(context).height),
        
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
            filled: true,
            fillColor: context.colorScheme.surfaceVariant.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              borderSide: BorderSide(
                color: context.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              borderSide: BorderSide(
                color: context.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              borderSide: BorderSide(
                color: context.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              borderSide: BorderSide(
                color: context.colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd(context)),
              borderSide: BorderSide(
                color: context.colorScheme.error,
                width: 2,
              ),
            ),
            contentPadding: DesignTokens.md(context).all,
          ),
        ),
      ],
    );
  }

  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Add haptic feedback
    HapticFeedback.lightImpact();

    final success = await widget.controller.createStore(
      storeName: _storeNameController.text.trim(),
      storeDescription: _storeDescriptionController.text.trim().isNotEmpty
          ? _storeDescriptionController.text.trim()
          : null,
      businessEmail: _businessEmailController.text.trim(),
      businessPhone: _businessPhoneController.text.trim().isNotEmpty
          ? _businessPhoneController.text.trim()
          : null,
      businessAddress: _businessAddressController.text.trim().isNotEmpty
          ? _businessAddressController.text.trim()
          : null,
    );

    if (success) {
      // Clear form
      _storeNameController.clear();
      _storeDescriptionController.clear();
      _businessEmailController.clear();
      _businessPhoneController.clear();
      _businessAddressController.clear();
    }
  }
}