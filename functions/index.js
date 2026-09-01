const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onCall} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const OpenAI = require('openai');

admin.initializeApp();
const db = admin.firestore();

const whatsappAccessToken = defineSecret('WHATSAPP_ACCESS_TOKEN');
const whatsappPhoneNumberId = defineSecret('WHATSAPP_PHONE_NUMBER_ID');
const whatsappTemplateName = defineSecret('WHATSAPP_TEMPLATE_NAME');

exports.analyzeTaskPriority = onCall(
    async (request) => {
      // Authentication check
      if (!request.auth) {
        throw new Error('The function must be called while authenticated.');
      }

      const {
        taskTitle,
        description,
        priority,
        category,
        dueDate,
        dueTime,
        daysRemaining,
        completed,
      } = request.data;

      const openai = new OpenAI({
        apiKey: process.env.OPENAI_API_KEY,
      });

      const prompt = `
        Analyze the following task and recommend a priority (Low, Medium, or High) and provide a reason.

        Task Details:
        - Title: ${taskTitle}
        - Description: ${description}
        - User Selected Priority: ${priority}
        - Category: ${category}
        - Due Date: ${dueDate}
        - Due Time: ${dueTime}
        - Days Remaining: ${daysRemaining}
        - Completed: ${completed}

        Rules:
        1. If a user selects Low priority but the task is due today or is overdue, recommend High priority.
        2. If a task is due far in the future, do not automatically upgrade it.
        3. Return the response in strictly JSON format: {"recommendedPriority": "High/Medium/Low", "reason": "Short explanation"}
      `;

      try {
        const response = await openai.chat.completions.create({
          model: 'gpt-4o-mini', // Using a commonly available stable model
          messages: [{role: 'user', content: prompt}],
          response_format: {type: 'json_object'},
        });

        const content = response.choices[0].message.content;
        return JSON.parse(content);
      } catch (error) {
        console.error('OpenAI API Error:', error);
        throw new Error('Failed to analyze task priority.');
      }
    },
);

exports.sendWhatsAppTaskReminders = onSchedule(
    {
      schedule: 'every 1 minutes',
      timeZone: 'UTC',
      secrets: [
        whatsappAccessToken,
        whatsappPhoneNumberId,
        whatsappTemplateName,
      ],
    },
    async () => {
      const now = admin.firestore.Timestamp.now();
      const tasks = await db
          .collection('tasks')
          .where('whatsappReminderSent', '==', false)
          .where('reminderAt', '<=', now)
          .limit(100)
          .get();

      for (const task of tasks.docs) {
        const data = task.data();
        if (data.completed === true || !data.userId) continue;

        const user = await db.collection('users').doc(data.userId).get();
        const phone = user.data()?.whatsappNumber || user.data()?.phone;
        if (!phone) continue;

        try {
          await sendWhatsAppMessage({
            phone,
            taskTitle: data.title || 'Task',
            dueTime: data.dueTime || 'soon',
          });
          await task.ref.update({
            whatsappReminderSent: true,
            whatsappReminderSentAt:
              admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (error) {
          console.error(`WhatsApp reminder failed for ${task.id}`, error);
        }
      }
    },
);

async function sendWhatsAppMessage({phone, taskTitle, dueTime}) {
  const response = await fetch(
      `https://graph.facebook.com/v23.0/${whatsappPhoneNumberId.value()}/messages`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${whatsappAccessToken.value()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          to: normalizePhone(phone),
          type: 'template',
          template: {
            name: whatsappTemplateName.value(),
            language: {code: 'en_US'},
            components: [
              {
                type: 'body',
                parameters: [
                  {type: 'text', text: taskTitle},
                  {type: 'text', text: dueTime},
                ],
              },
            ],
          },
        }),
      },
  );

  if (!response.ok) {
    const details = await response.text();
    throw new Error(
        `WhatsApp API returned ${response.status}: ${details}`,
    );
  }
}

function normalizePhone(phone) {
  return phone.toString().replace(/[^0-9]/g, '');
}
