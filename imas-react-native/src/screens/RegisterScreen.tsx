import React, { useState } from 'react';
import {
  View, Text, StyleSheet, TextInput, TouchableOpacity,
  KeyboardAvoidingView, Platform, ScrollView, ActivityIndicator, Alert
} from 'react-native';
import { Mail, Lock, User, ArrowLeft, ArrowRight, Eye, EyeOff } from 'lucide-react-native';
import { COLORS, SIZES, UI_STYLES } from '../theme/theme';

export default function RegisterScreen({ navigation }: any) {
  const [step, setStep] = useState(0);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleNext = () => {
    if (!name.trim() || !email.includes('@')) {
      Alert.alert('Validation', 'Please fill in all fields correctly.');
      return;
    }
    setStep(1);
  };

  const handleRegister = () => {
    if (password.length < 6) {
      Alert.alert('Validation', 'Password must be at least 6 characters.');
      return;
    }
    if (password !== confirm) {
      Alert.alert('Validation', 'Passwords do not match.');
      return;
    }
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      navigation.replace('MainTabs');
    }, 1500);
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={styles.container}
    >
      <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        {/* Header */}
        <View style={styles.headerRow}>
          <TouchableOpacity
            style={styles.backBtn}
            onPress={() => step === 1 ? setStep(0) : navigation.goBack()}
          >
            <ArrowLeft color={COLORS.text} size={20} />
          </TouchableOpacity>
          <View style={styles.stepDots}>
            <View style={[styles.dot, step >= 0 && styles.dotActive]} />
            <View style={[styles.dot, step >= 1 && styles.dotActive]} />
          </View>
        </View>

        {/* Title */}
        <View style={styles.titleBlock}>
          <Text style={styles.title}>{step === 0 ? 'Create\nAccount' : 'Set Your\nPassword'}</Text>
          <Text style={styles.subtitle}>
            {step === 0 ? 'Join IMAS to protect your fleet' : 'Choose a strong password to secure your account'}
          </Text>
        </View>

        {/* Form */}
        <View style={styles.form}>
          {step === 0 ? (
            <>
              <View style={styles.inputRow}>
                <User color={COLORS.secondary} size={20} />
                <TextInput
                  style={styles.input}
                  placeholder="Full Name"
                  placeholderTextColor={COLORS.textSecondary}
                  value={name}
                  onChangeText={setName}
                />
              </View>
              <View style={styles.inputRow}>
                <Mail color={COLORS.secondary} size={20} />
                <TextInput
                  style={styles.input}
                  placeholder="Email Address"
                  placeholderTextColor={COLORS.textSecondary}
                  value={email}
                  onChangeText={setEmail}
                  keyboardType="email-address"
                  autoCapitalize="none"
                />
              </View>
              <TouchableOpacity style={styles.primaryBtn} onPress={handleNext}>
                <Text style={styles.primaryBtnText}>CONTINUE</Text>
                <ArrowRight color={COLORS.primary} size={18} />
              </TouchableOpacity>
            </>
          ) : (
            <>
              <View style={styles.inputRow}>
                <Lock color={COLORS.primary} size={20} />
                <TextInput
                  style={styles.input}
                  placeholder="Password"
                  placeholderTextColor={COLORS.textSecondary}
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry={!showPass}
                />
                <TouchableOpacity onPress={() => setShowPass(!showPass)}>
                  {showPass ? <EyeOff color={COLORS.textSecondary} size={18} /> : <Eye color={COLORS.textSecondary} size={18} />}
                </TouchableOpacity>
              </View>
              <View style={styles.inputRow}>
                <Lock color={COLORS.primary} size={20} />
                <TextInput
                  style={styles.input}
                  placeholder="Confirm Password"
                  placeholderTextColor={COLORS.textSecondary}
                  value={confirm}
                  onChangeText={setConfirm}
                  secureTextEntry={!showConfirm}
                />
                <TouchableOpacity onPress={() => setShowConfirm(!showConfirm)}>
                  {showConfirm ? <EyeOff color={COLORS.textSecondary} size={18} /> : <Eye color={COLORS.textSecondary} size={18} />}
                </TouchableOpacity>
              </View>
              <TouchableOpacity style={styles.primaryBtn} onPress={handleRegister} disabled={loading}>
                {loading ? <ActivityIndicator color={COLORS.primary} /> : <Text style={styles.primaryBtnText}>CREATE ACCOUNT</Text>}
              </TouchableOpacity>
            </>
          )}

          <View style={styles.loginRow}>
            <Text style={styles.loginText}>Already have an account? </Text>
            <TouchableOpacity onPress={() => navigation.goBack()}>
              <Text style={styles.loginLink}>Sign In</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  scroll: { flexGrow: 1, padding: SIZES.lg, paddingTop: SIZES.xxl },
  headerRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: SIZES.xl },
  backBtn: {
    width: 44, height: 44, borderRadius: 14,
    backgroundColor: 'rgba(255,255,255,0.05)',
    justifyContent: 'center', alignItems: 'center',
  },
  stepDots: { flexDirection: 'row', gap: 8 },
  dot: { width: 10, height: 10, borderRadius: 5, backgroundColor: 'rgba(0,240,255,0.2)' },
  dotActive: { width: 24, backgroundColor: COLORS.primary },
  titleBlock: { marginBottom: SIZES.xl },
  title: { fontSize: 34, fontWeight: '900', color: COLORS.text, lineHeight: 40, marginBottom: 10 },
  subtitle: { fontSize: 15, color: COLORS.textSecondary },
  form: { ...UI_STYLES.glassmorphism, padding: SIZES.xl, gap: SIZES.md },
  inputRow: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: 'rgba(0,0,0,0.3)',
    borderWidth: 1, borderColor: COLORS.glassBorder,
    borderRadius: SIZES.sm, paddingHorizontal: SIZES.md,
    gap: 10,
  },
  input: { flex: 1, color: COLORS.text, paddingVertical: SIZES.md, fontSize: 15 },
  primaryBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    backgroundColor: 'rgba(112,0,255,0.15)',
    borderWidth: 1, borderColor: COLORS.secondary,
    padding: SIZES.md, borderRadius: SIZES.sm, gap: 8,
  },
  primaryBtnText: { color: COLORS.primary, fontSize: 16, fontWeight: 'bold', letterSpacing: 2 },
  loginRow: { flexDirection: 'row', justifyContent: 'center', marginTop: SIZES.sm },
  loginText: { color: COLORS.textSecondary, fontSize: 14 },
  loginLink: { color: COLORS.primary, fontSize: 14, fontWeight: 'bold' },
});
