/// مدل داده‌ی سوال - دقیقاً منطبق با ساختار JSON بانک ۱۵۰ سوالی
class Question {
  final int id;
  final String type; // مثلاً: کوته‌پاسخ، بلند، پایتخت و ...
  final String category; // مثلاً: جانوران، تکنولوژی
  final int difficulty;
  final int time; // زمان پیشنهادی سوال (ثانیه) - فعلاً استفاده نمی‌شود، تایمر بازی ثابت ۷ ثانیه است
  final String question;
  final String answer;

  const Question({
    required this.id,
    required this.type,
    required this.category,
    required this.difficulty,
    required this.time,
    required this.question,
    required this.answer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      type: json['type'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as int,
      time: json['time'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'category': category,
        'difficulty': difficulty,
        'time': time,
        'question': question,
        'answer': answer,
      };
}
