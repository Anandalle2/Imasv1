import React, { useEffect } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { COLORS, SIZES, UI_STYLES } from '../theme/theme';

export default function SplashScreen({ navigation }: any) {
  const fadeAnim = new Animated.Value(0);
  const scaleAnim = new Animated.Value(0.9);

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 1500,
        useNativeDriver: true,
      }),
      Animated.spring(scaleAnim, {
        toValue: 1,
        friction: 4,
        useNativeDriver: true,
      }),
    ]).start();

    const timer = setTimeout(() => {
      navigation.replace('Welcome');
    }, 3000);

    return () => clearTimeout(timer);
  }, []);

  return (
    <View style={styles.container}>
      <Animated.View
        style={[
          styles.logoContainer,
          {
            opacity: fadeAnim,
            transform: [{ scale: scaleAnim }],
          },
        ]}
      >
        <Text style={styles.logoText}>IMAS</Text>
        <Text style={styles.subtitleText}>Intelligent Monitoring</Text>
        <Text style={styles.subtitleText}>Advanced Safety</Text>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
    justifyContent: 'center',
    alignItems: 'center',
  },
  logoContainer: {
    ...UI_STYLES.glassmorphism,
    ...UI_STYLES.glow,
    padding: SIZES.xl,
    alignItems: 'center',
  },
  logoText: {
    fontSize: 48,
    color: COLORS.primary,
    fontWeight: 'bold',
    marginBottom: SIZES.sm,
  },
  subtitleText: {
    fontSize: 16,
    color: COLORS.textSecondary,
    letterSpacing: 2,
  },
});
