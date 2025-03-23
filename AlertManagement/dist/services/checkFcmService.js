"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkFcmService = void 0;
const db_1 = __importDefault(require("../db")); // Ensure supabase client is correctly imported
const dotenv = __importStar(require("dotenv"));
dotenv.config(); // Load environment variables
class checkFcmService {
    checkAndUpdateFcmToken(user_id, fcm_token) {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                // Fetch the current FCM token for the given user ID from the database
                const { data, error } = yield db_1.default
                    .from('userInfo') // Replace 'userInfo' with your actual table name
                    .select('fcm_token') // Select the fcm_token column
                    .eq('id', user_id) // Match the user ID
                    .single(); // Ensure only one record is fetched
                if (error) {
                    console.error('Error fetching FCM token:', error);
                    return { success: false, message: 'Error fetching FCM token from the database.' };
                }
                // Check if the current FCM token matches the given token
                if (data.fcm_token === fcm_token) {
                    return { success: true, message: 'FCM token is already up-to-date.' };
                }
                else {
                    const { error: updateError } = yield db_1.default
                        .from('userInfo') // Replace 'userInfo' with your actual table name
                        .update({ fcm_token }) // Update the fcm_token column
                        .eq('id', user_id); // Match the user ID
                    if (updateError) {
                        console.error('Error updating FCM token:', updateError);
                        return { success: false, message: 'Error updating FCM token in the database.' };
                    }
                    return { success: true, message: 'FCM token updated successfully.' };
                }
            }
            catch (err) {
                console.error('Unexpected error:', err);
                return { success: false, message: 'An unexpected error occurred.' };
            }
        });
    }
}
exports.checkFcmService = checkFcmService;
