import { CameraView, useCameraPermissions } from 'expo-camera';
import { useRef, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Modal,
  Image,
} from 'react-native';
import { colors, spacing } from '../theme';

type Props = {
  visible: boolean;
  onClose: () => void;
  onCapture: (uri: string) => void;
};

export function FotoModal({ visible, onClose, onCapture }: Props) {
  const [permission, requestPermission] = useCameraPermissions();
  const cameraRef = useRef<CameraView>(null);
  const [preview, setPreview] = useState<string | null>(null);

  const takePhoto = async () => {
    const photo = await cameraRef.current?.takePictureAsync({
      quality: 0.82,
      skipProcessing: true,
    });
    if (photo?.uri) setPreview(photo.uri);
  };

  const confirm = () => {
    if (preview) {
      onCapture(preview);
      setPreview(null);
      onClose();
    }
  };

  if (!permission) return null;

  return (
    <Modal visible={visible} animationType="slide" onRequestClose={onClose}>
      <View style={styles.container}>
        {!permission.granted ? (
          <View style={styles.center}>
            <Text style={styles.msg}>Se necesita permiso de cámara.</Text>
            <TouchableOpacity style={styles.btn} onPress={requestPermission}>
              <Text style={styles.btnText}>Permitir cámara</Text>
            </TouchableOpacity>
          </View>
        ) : preview ? (
          <View style={styles.flex}>
            <Image source={{ uri: preview }} style={styles.preview} />
            <View style={styles.actions}>
              <TouchableOpacity style={styles.secondary} onPress={() => setPreview(null)}>
                <Text>Repetir</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.btn} onPress={confirm}>
                <Text style={styles.btnText}>Usar foto</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          <View style={styles.flex}>
            <CameraView ref={cameraRef} style={styles.camera} facing="front" />
            <View style={styles.actions}>
              <TouchableOpacity style={styles.secondary} onPress={onClose}>
                <Text>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.btn} onPress={() => void takePhoto()}>
                <Text style={styles.btnText}>Capturar</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  flex: { flex: 1 },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: spacing.lg },
  msg: { color: '#fff', marginBottom: spacing.md, textAlign: 'center' },
  camera: { flex: 1 },
  preview: { flex: 1, resizeMode: 'contain' },
  actions: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: spacing.md,
    backgroundColor: colors.card,
  },
  btn: {
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: 8,
  },
  btnText: { color: '#fff', fontWeight: '700' },
  secondary: { padding: spacing.md },
});
