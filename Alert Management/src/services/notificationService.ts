import { PushService } from './pushService';

export class NotificationService {
  private pushService: PushService;

  constructor() {
    this.pushService = new PushService();
  }

  async sendPushNotification(userId: string, message: string) {
    try {
      await this.pushService.send(userId, message);
      console.log('Push notification sent successfully');
    } catch (error) {
      console.error('Error sending push notification', error);
    }
  }
}

