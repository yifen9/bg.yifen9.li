import { defineCollection, image, z } from "astro:content";

const blog = defineCollection({
	type: "content",
	schema: z.object({
		title: z.string(),
		date: z.string(),
		cover: image(),
		players: z.array(z.string()).nonempty(),
		games: z
			.array(
				z
					.object({
						name: z.string(),
						session_id: z.string(),
						photo: z.string().optional(),
						participants: z.array(z.string()).nonempty(),
						ranks: z.array(z.number()).nonempty(),
						scores: z.array(z.number()).optional(),
						ratings: z.record(z.string(), z.number()).optional(),
					})
					.refine((v) => v.participants.length === v.ranks.length, {
						message: "participants and ranks length mismatch",
					}),
			)
			.nonempty(),
	}),
});

export const collections = { blog };
