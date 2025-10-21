const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Inicializa a aplicação Firebase Admin para poder aceder à base de dados
admin.initializeApp();

// Define a Cloud Function que será acionada na criação de um documento em 'chamados'
exports.sendEmergencyCallNotification = functions.firestore
    .document("chamados/{chamadoId}")
    .onCreate(async (snapshot, context) => {
      // 1. Obtém os dados do chamado que acabou de ser criado
      const chamadoData = snapshot.data();

      if (!chamadoData) {
        console.log("Nenhum dado encontrado no chamado.");
        return null;
      }

      const remetenteNome = chamadoData.remetenteNome;
      const destinatarioId = chamadoData.destinatarioId;

      console.log(`Novo chamado de ${remetenteNome} para o utilizador ${destinatarioId}`);

      if (!destinatarioId) {
        console.log("ID do destinatário não encontrado no chamado.");
        return null;
      }

      // 2. Procura o documento do utilizador destinatário para encontrar o seu token de notificação
      const userDoc = await admin
          .firestore()
          .collection("usuarios")
          .doc(destinatarioId)
          .get();

      if (!userDoc.exists) {
        console.log(`Utilizador ${destinatarioId} não encontrado.`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`Token FCM não encontrado para o utilizador ${destinatarioId}.`);
        return null;
      }

      // 3. Monta a mensagem da notificação
      const payload = {
        notification: {
          title: "⚠️ Chamado de Emergência!",
          body: `${remetenteNome} precisa da sua ajuda. Toque para ver a localização.`,
          sound: "default", // Adiciona som à notificação
        },
        token: fcmToken,
        // Define a prioridade alta para Android
        android: {
          priority: "high",
        },
        // Define a prioridade alta para APNs (iOS)
        apns: {
          headers: {
            "apns-priority": "10",
          },
        },
      };

      // 4. Envia a notificação utilizando o Firebase Cloud Messaging
      try {
        console.log(`A enviar notificação para o token: ${fcmToken}`);
        const response = await admin.messaging().send(payload);
        console.log("Notificação enviada com sucesso:", response);
      } catch (error) {
        console.error("Erro ao enviar notificação:", error);
      }

      return null;
    });
